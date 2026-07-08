//
//  AddWorryViewModel.swift
//  SilentDay
//
//  追加画面(S-02)のViewModelです。
//  入力テキストの管理と、「保存+通知スケジュール」の一連の処理を担当します。
//

import Foundation
import SwiftData
import Observation

@Observable
final class AddWorryViewModel {

    // データの保存はRepositoryに任せる
    private let repository: WorryRepository

    // MARK: - 画面が参照する状態

    // テキスト入力欄と双方向バインディングする入力内容
    var text: String = ""

    // エラー発生時にアラート表示で使うメッセージ。nilならエラーなし
    var errorMessage: String?

    // MARK: - 初期化

    init(context: ModelContext) {
        self.repository = WorryRepository(context: context)
    }

    // MARK: - 入力チェック

    // 保存ボタンを押せる状態かどうか。
    // trimmingCharactersで前後の空白・改行を取り除き、
    // 「スペースだけの入力」では保存できないようにしています。
    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - 保存処理

    // 入力内容を保存し、通知を予約します。
    // 戻り値: 成功したらtrue(画面を閉じてよい)、失敗したらfalse(画面に留まる)
    func save() -> Bool {
        // 前後の空白を取り除いた「きれいな」テキストを保存する
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        do {
            // --- 登録数の上限チェック(仕様書4.2 / NF-02) ---
            // 1項目=通知3件のため、同時最大10件に制限して
            // iOSのローカル通知64件制約に余裕を持たせます。
            let activeCount = try repository.fetchActive().count
            guard activeCount < 10 else {
                errorMessage = "同時に見守れるのは10件までです。\nどれかが穏やかに終わるのを待つか、整理してから登録してください。"
                return false
            }

            // --- 1. データベースに保存 ---
            let item = try repository.add(text: trimmed)

            // --- 2. 6h/12h/24h後のローカル通知を予約 ---
            // 保存と通知予約は必ずセットで行います(片方だけだと通知が届かない/
            // 存在しないアイテムの通知が届く、といった不整合が起きるため)。
            NotificationService.shared.scheduleNotifications(for: item)

            return true
        } catch {
            errorMessage = "保存に失敗しました。もう一度お試しください。"
            return false
        }
    }
}
