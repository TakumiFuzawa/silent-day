//
//  WorryItem.swift
//  SilentDay
//
//  ユーザーが登録した「不安なこと」1件分を表すデータモデル。
//  SwiftData(iOS 17から使える新しいデータ保存の仕組み)を使って、
//  アプリを終了してもデータが端末内に保存され続けるようにしています。
//

import Foundation
import SwiftData
import SwiftUI

// @Model は「このクラスをSwiftDataで保存できるモデルにする」という印(マクロ)です。
// これを付けるだけで、SwiftDataが自動的にデータベースへの保存・読み込みを
// 面倒みてくれるようになります。
//
// final は「このクラスは継承(子クラスの作成)を禁止する」という意味です。
// SwiftDataのモデルはfinalにするのが推奨されています。
@Model
final class WorryItem {
    // @Attribute(.unique) は「この値はデータベース内で重複してはいけない」という指定です。
    // UUIDは「世界中で二度と同じ値が生成されない」ランダムなID(一意識別子)なので、
    // 各不安アイテムを確実に区別するために使います。
    @Attribute(.unique) var id: UUID

    // ユーザーが入力した不安の内容(例:「明日のプレゼンが心配」)
    var text: String

    // この不安を登録した日時。
    // 「登録から6時間後・12時間後・24時間後」の通知をスケジュールする際の
    // 基準となる、とても重要な値です。
    var createdAt: Date

    // 24時間が経過して「穏やかな一日だった」と認定されたかどうか。
    // true  = 完了(何も起きずに24時間が過ぎた)
    // false = まだ経過観察中
    //
    // 完了しても削除せずこのフラグで管理することで、
    // 後から履歴(過去にどんな不安があったか)を振り返れるようにしています。
    var isCompleted: Bool

    // イニシャライザ(このモデルの新しいインスタンスを作るときに呼ばれる処理)。
    // 呼び出す側は不安のテキストを渡すだけでOKです。
    // 例: let worry = WorryItem(text: "明日のプレゼンが心配")
    init(text: String) {
        self.id = UUID()          // 新しいランダムIDを自動生成
        self.text = text          // 引数で受け取ったテキストをそのまま保存
        self.createdAt = Date()   // Date() は「今この瞬間」の日時
        self.isCompleted = false  // 登録直後はまだ未完了なので false
    }
}
// 動作確認用(確認が終わったら削除してOK)
#Preview {
    let container = try! ModelContainer(for: WorryItem.self, PeacefulLog.self)
    let context = container.mainContext
    let item = WorryItem(text: "テスト用の不安項目")
    context.insert(item)
    return Text("動作確認: \(item.text)")
}
