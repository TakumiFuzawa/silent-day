//
//  HomeViewModel.swift
//  SilentDay
//
//  ホーム画面(S-01)の「頭脳」にあたるViewModelです。
//
//  ■ MVVMパターンにおけるViewModelの役割
//  - View(画面)は「表示すること」だけに集中する
//  - ViewModelは「データの取得・加工・画面用の状態管理」を担当する
//  - データの実際の読み書きはRepositoryに任せる
//  この分担により、画面とロジックが混ざらず、テストや修正がしやすくなります。
//

import Foundation
import SwiftData
import Observation  // @Observable マクロを使うために必要

// @Observable は iOS 17 から使える新しい仕組みで、
// 「このクラスのプロパティが変化したら、それを使っている画面を自動で再描画する」
// ようにしてくれるマクロです(以前の ObservableObject + @Published の進化版)。
@Observable
final class HomeViewModel {

    // データ操作はRepositoryに任せる(ViewModelはSwiftDataの詳細を知らなくてよい)
    private let repository: WorryRepository

    // 24時間経過した不安を「完了+穏やかな日ログ記録」するサービス(F-05)
    private let completionService: WorryCompletionService

    // MARK: - 画面が参照する状態

    // 画面に表示する「経過観察中の不安」の一覧。
    // この配列が変わると、@Observableの働きで画面が自動的に更新されます。
    var worries: [WorryItem] = []

    // エラーが起きたときにアラート表示などで使うメッセージ。nilならエラーなし
    var errorMessage: String?

    // MARK: - 初期化

    // ModelContext(SwiftDataの窓口)を受け取り、Repositoryを組み立てます。
    // ContextはView側の @Environment(\.modelContext) から渡してもらいます。
    init(context: ModelContext) {
        self.repository = WorryRepository(context: context)
        self.completionService = WorryCompletionService(context: context)
    }

    // MARK: - データ操作

    // 経過観察中(未完了)の不安を読み込みます。画面表示時に呼びます。
    func loadWorries() {
        do {
            // 読み込みの前に「24時間経過した不安」の完了処理を行います(F-05)。
            // アプリはバックグラウンドで動けないため、画面を開いたこの
            // タイミングでまとめてチェックする方式です(WorryCompletionService参照)。
            // 完了した項目はfetchActive()の結果から自然に消え、
            // 穏やかな日ログ(カレンダー画面)に記録されます。
            try completionService.completeExpiredWorries()

            worries = try repository.fetchActive()
        } catch {
            errorMessage = "データの読み込みに失敗しました"
        }
    }

    // 不安を削除します。
    // 仕様書4.2のとおり、データ削除と通知キャンセルは必ずセットで行います。
    func delete(_ item: WorryItem) {
        // 1. 予約済みのローカル通知(6h/12h/24h)をキャンセル
        NotificationService.shared.cancelNotifications(for: item)
        // 2. データベースから削除
        do {
            try repository.delete(item)
            loadWorries()  // 一覧を読み込み直して画面を最新にする
        } catch {
            errorMessage = "削除に失敗しました"
        }
    }

    // MARK: - 画面表示用の計算

    // 24時間に対する経過の割合(0.0〜1.0)を返します。進捗バーの長さに使います。
    // 例: 登録から12時間経過 → 0.5(バーが半分まで伸びる)
    func progress(of item: WorryItem, at now: Date = Date()) -> Double {
        let elapsed = now.timeIntervalSince(item.createdAt)  // 経過秒数
        let full = 24.0 * 3600                               // 24時間を秒に換算
        // min(..., 1.0) で「24時間を超えても1.0まで」に制限(バーがはみ出さないように)
        return min(max(elapsed / full, 0), 1.0)
    }

    // 経過時間を「3時間経過」のような表示用テキストにして返します。
    func elapsedText(of item: WorryItem, at now: Date = Date()) -> String {
        let elapsedHours = Int(now.timeIntervalSince(item.createdAt) / 3600)
        if elapsedHours < 1 {
            let minutes = Int(now.timeIntervalSince(item.createdAt) / 60)
            return "\(max(minutes, 0))分経過"
        }
        return "\(elapsedHours)時間経過"
    }
}
