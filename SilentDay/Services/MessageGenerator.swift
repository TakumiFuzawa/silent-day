//
//  MessageGenerator.swift
//  SilentDay
//
//  通知に表示する文言をランダムに生成するサービスです(仕様書4.3 / F-04対応)。
//
//  ■ 仕組み
//  「登録からどれくらい時間が経ったか」に応じて3つの時間帯に分け、
//  それぞれの時間帯ごとに用意したテンプレート配列から randomElement() で
//  1つを選びます。同じ状況でも毎回少しずつ違う表現になり、
//  通知が機械的に感じられないようにする工夫です。
//
//  ■ 文言のトーン(仕様書セクション5)
//  断定的すぎず、静かに寄り添う表現を心がけています。
//  テンプレートを増やしたいときは、該当する配列に文字列を足すだけでOKです。
//

import Foundation
import SwiftUI  // ファイル末尾の #Preview で使用

// 通知文言を生成するクラス。
// データベース等に依存せず単体で動くので、UI実装前にロジックだけ検証できます(仕様書8)。
final class MessageGenerator {

    // MARK: - 経過時間帯の定義

    // 登録からの経過時間を3つの「時間帯」に分類するための列挙型(enum)です。
    // enumを使うと「この3種類しか存在しない」ことをコードで保証でき、
    // if文の書き間違いによるバグを防げます。
    enum Phase {
        case early    // 0〜6時間: 登録して間もない時間帯
        case middle   // 6〜24時間: 半日を越えて安心が育っていく時間帯
        case completed // 24時間以降: 穏やかな一日として完了した時間帯

        // 経過秒数から該当する時間帯を判定する static メソッド。
        // TimeIntervalはDouble型の別名で、秒数を表します(3600秒 = 1時間)。
        static func from(elapsed: TimeInterval) -> Phase {
            let hours = elapsed / 3600  // 秒を時間に変換
            switch hours {
            case ..<6:    return .early      // 6時間未満
            case ..<24:   return .middle     // 6時間以上24時間未満
            default:      return .completed  // 24時間以上
            }
        }
    }

    // MARK: - テンプレート文言

    // 時間帯ごとの文言テンプレート。
    // 「静かに寄り添うトーン」を守りつつ、各3パターン以上用意しています。
    // private let にしているのは、外部から書き換えられないようにするためです。

    // 0〜6時間: まだ登録したばかり。そっと見守り始めたことを伝える
    private let earlyTemplates = [
        "まだ静かな時間が続いています。",
        "いまのところ、何も起きていません。そのままで大丈夫です。",
        "静かに見守っています。世界は今日も穏やかなようです。",
        "小さな心配を預かりました。ここから先は、静けさに任せましょう。"
    ]

    // 6〜24時間: 半日を越えた安心を、少しずつ言葉にする
    private let middleTemplates = [
        "半日が過ぎました。あなたの心配は、まだ現実になっていません。",
        "時間は静かに流れています。今日も何も起きていません。",
        "気づけばもう、こんなに穏やかな時間が積み重なっています。",
        "心配していたことは、今日も遠くにいるようです。"
    ]

    // 24時間以降: 穏やかな一日の完了を、そっと祝福する
    private let completedTemplates = [
        "穏やかな一日でした。何も起きないまま、今日が終わっていきます。",
        "24時間、世界は静かなままでした。おつかれさまです。",
        "心配ごとは、結局訪れませんでした。今日は穏やかな日として記録されます。",
        "何もない一日は、それだけで小さな贈り物かもしれません。"
    ]

    // MARK: - 文言生成

    // 時間帯を指定して文言を1つランダムに取得します。
    // randomElement() は配列が空のときだけnilを返すため、
    // 万一に備えて ?? で予備の文言(フォールバック)を用意しています。
    func message(for phase: Phase) -> String {
        switch phase {
        case .early:
            return earlyTemplates.randomElement() ?? "静かな時間が続いています。"
        case .middle:
            return middleTemplates.randomElement() ?? "今日も何も起きていません。"
        case .completed:
            return completedTemplates.randomElement() ?? "穏やかな一日でした。"
        }
    }

    // 「登録日時」から自動で時間帯を判定して文言を返す便利メソッド。
    // 通知スケジュール時や画面表示時は、基本こちらを使えばOKです。
    // 例: generator.message(since: worryItem.createdAt)
    func message(since createdAt: Date, now: Date = Date()) -> String {
        // timeIntervalSince で2つの日時の差を秒数として取得
        let elapsed = now.timeIntervalSince(createdAt)
        let phase = Phase.from(elapsed: elapsed)
        return message(for: phase)
    }
}

// 動作確認用のプレビュー。
// 3つの時間帯それぞれの文言が生成されることを一覧で確認できます。
// (プレビューを再描画するたびに文言がランダムに変わります)
#Preview {
    let generator = MessageGenerator()

    return VStack(alignment: .leading, spacing: 16) {
        Text("【0〜6時間】")
        Text(generator.message(for: .early))

        Text("【6〜24時間】")
        Text(generator.message(for: .middle))

        Text("【24時間以降】")
        Text(generator.message(for: .completed))

        // 経過時間からの自動判定も確認(3時間前に登録した想定 → early判定になる)
        Text("【自動判定: 3時間前に登録】")
        Text(generator.message(since: Date().addingTimeInterval(-3 * 3600)))
    }
    .padding()
}
