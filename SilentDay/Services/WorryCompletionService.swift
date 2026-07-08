//
//  WorryCompletionService.swift
//  SilentDay
//
//  「24時間経過した不安を完了扱いにして、穏やかな日ログに記録する」
//  一連の処理を担当するサービスです(仕様書F-05対応)。
//
//  ■ なぜ「アプリを開いたとき」にチェックするのか
//  このアプリは通信もバックグラウンド処理も行わないため(NF-01)、
//  「24時間経過した瞬間」に自動でコードを動かすことはできません。
//  そこで、アプリを開いた(ホーム画面を表示した)タイミングで
//  「24時間を過ぎている不安はないか?」をまとめてチェックし、
//  あれば完了処理+ログ記録を行う方式にしています。
//  ※ 24時間後のローカル通知(「穏やかな一日でした」)自体は
//    NotificationServiceが予約済みなので、アプリを開かなくても届きます。
//

import Foundation
import SwiftData

final class WorryCompletionService {

    // 不安の更新とログの追加、2つのRepositoryを使います
    private let worryRepository: WorryRepository
    private let logRepository: LogRepository

    init(context: ModelContext) {
        self.worryRepository = WorryRepository(context: context)
        self.logRepository = LogRepository(context: context)
    }

    // 24時間経過した不安をすべて「完了」にし、PeacefulLogへ記録します。
    // 呼び出しタイミング: ホーム画面・カレンダー画面の表示時(onAppear)を想定。
    // 何件完了処理したかを返します(0なら何も起きなかった)。
    @discardableResult
    func completeExpiredWorries(now: Date = Date()) throws -> Int {
        // 経過観察中(未完了)の不安を全件取得
        // (CLAUDE.mdの方針どおり、絞り込みはSwift側のfilterで行っています)
        let activeWorries = try worryRepository.fetchActive()

        // そのうち「登録から24時間以上経過したもの」だけを抜き出す
        let expired = activeWorries.filter { item in
            now.timeIntervalSince(item.createdAt) >= 24 * 3600
        }

        for item in expired {
            // --- 1. 完了フラグを立てる(穏やか認定) ---
            try worryRepository.markAsCompleted(item)

            // --- 2. 穏やかな日ログに記録する ---
            // 記録する日付は「登録から24時間後」= 穏やか認定が成立した日。
            // (例: 7月7日 21時登録 → 7月8日 21時成立 → 「7月8日」のログに記録)
            // LogRepository.add が日単位への丸めと「同じ日への追記」を
            // 内部でやってくれるので、ここでは日時をそのまま渡せばOKです。
            let completionDate = item.createdAt.addingTimeInterval(24 * 3600)
            try logRepository.add(
                date: completionDate,
                completedWorryTexts: [item.text]
            )
        }

        return expired.count
    }
}
