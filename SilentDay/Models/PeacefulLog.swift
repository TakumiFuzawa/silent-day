//
//  PeacefulLog.swift
//  SilentDay
//
//  「穏やかだった日」1日分の記録を表すデータモデル。
//  不安が何も起きずに24時間経過すると、この記録が自動生成され、
//  カレンダー画面(S-04)で「穏やかな日」として振り返れるようになります。
//

import Foundation
import SwiftData

// WorryItemと同じく、@Modelを付けてSwiftDataで保存できるモデルにしています。
@Model
final class PeacefulLog {
    // ログの対象となる日付。
    // @Attribute(.unique) を付けているので「1日につきログは1件だけ」という
    // ルールがデータベースレベルで保証されます。
    //
    // 注意: Dateは本来「2026年7月7日 14時30分15秒」のように時刻まで含むため、
    // このモデルに保存する際は必ず「日単位に丸めた値」
    // (例: Calendar.current.startOfDay(for:) で取得したその日の0時0分)を
    // 渡すようにしてください。時刻がバラバラだと同じ日でも別の値と
    // みなされてしまい、「1日1件」のルールが機能しなくなります。
    @Attribute(.unique) var date: Date

    // その日に「穏やか」認定された不安の内容を、文字列の配列として保存します。
    // 例: ["明日のプレゼンが心配", "健康診断の結果が気になる"]
    //
    // なぜWorryItemへの参照(リレーション)ではなく文字列のコピーを持つのか?
    // → これは「スナップショット保存」という考え方です。
    //   元のWorryItemが後から削除・変更されても、この記録は当時のまま残ります。
    //   モデル同士を関連付ける正規化(リレーション設計)よりもシンプルで、
    //   個人開発規模のアプリならこの方式で十分です(仕様書セクション3の方針)。
    var completedWorryTexts: [String]

    // イニシャライザ。日付と、その日に完了した不安のテキスト一覧を受け取ります。
    // 例: let log = PeacefulLog(
    //         date: Calendar.current.startOfDay(for: Date()),
    //         completedWorryTexts: ["明日のプレゼンが心配"]
    //     )
    init(date: Date, completedWorryTexts: [String]) {
        self.date = date
        self.completedWorryTexts = completedWorryTexts
    }
}
