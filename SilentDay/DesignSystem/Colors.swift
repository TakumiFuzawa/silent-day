//
//  Colors.swift
//  SilentDay
//
//  アプリ全体で使うカラーパレットの定義です(仕様書5.1の確定版に対応)。
//
//  ■ 使い方のルール(仕様書5.4)
//  各Viewでは直接カラーコードを書かず、必ずここの定数経由で色を使います。
//    ○ 良い例: .background(Color.bgBase)
//    × 悪い例: .background(Color(red: 0.07, ...))  ← 色の変更時に全画面の修正が必要になる
//
//  ■ Assets.xcassetsへのカラーセット登録が前提です
//  下の各定数は Color("名前") の形でアセットカタログから色を読み込みます。
//  そのため、先にXcodeで以下の手順でカラーセットを登録してください。
//
//  【登録手順(色ごとに繰り返す)】
//  1. Xcodeで Assets.xcassets を開く
//  2. 左下の「+」ボタン →「Color Set」を選択
//  3. 名前を下の表の「アセット名」に変更(大文字小文字も正確に!)
//  4. 右のAttributes Inspectorで Appearances を「None」にする
//     (このアプリは常にダークテーマなので、ライト/ダークの出し分けは不要)
//  5. 色をクリック → Color Panelの「カラーつまみ(2番目のタブ)」→「RGB Sliders」
//     → Hex欄に下の表のカラーコードを入力
//
//  【登録する8色の一覧(仕様書5.1)】
//  | アセット名     | カラーコード | 用途                                   |
//  |--------------|------------|----------------------------------------|
//  | BgBase       | #12121A    | 画面全体の背景                           |
//  | BgCard       | #1C1C28    | リスト項目・カード                        |
//  | BgSpecial    | #0D0D13    | 通知詳細画面など、他より少し暗くする画面     |
//  | AccentMain   | #8B7FD1    | ボタン・強調テキスト・進捗バー              |
//  | AccentSub    | #D4A574    | 完了マーク・カレンダーの穏やかな日マーカー    |
//  | TextMain     | #E8E6F0    | 見出し・本文                             |
//  | TextSub      | #8A8798    | 補足説明・タイムスタンプ                   |
//  | Separator    | #2A2A38    | セパレーター(罫線・細め・控えめに)         |
//

import SwiftUI

// Colorを「拡張(extension)」して、独自の色定数を追加します。
// extensionとは、既存の型に後から機能を足せるSwiftの仕組みです。
// これにより Color.bgBase のように、標準の色と同じ感覚で使えるようになります。
extension Color {

    // MARK: - 背景色

    /// 背景(ベース): #12121A — 画面全体の背景に使う
    static let bgBase = Color("BgBase")

    /// 背景(カード): #1C1C28 — リスト項目やカードの背景に使う
    static let bgCard = Color("BgCard")

    /// 背景(特別画面): #0D0D13 — 通知詳細画面(S-03)など、他より暗くしたい画面に使う
    static let bgSpecial = Color("BgSpecial")

    // MARK: - アクセント色

    /// アクセント(メイン): #8B7FD1 — ボタン・強調テキスト・進捗バーに使う
    static let accentMain = Color("AccentMain")

    /// アクセント(サブ): #D4A574 — 完了マーク・カレンダーの穏やかな日マーカーに使う
    static let accentSub = Color("AccentSub")

    // MARK: - テキスト色

    /// テキスト(メイン): #E8E6F0 — 見出し・本文に使う
    static let textMain = Color("TextMain")

    /// テキスト(サブ): #8A8798 — 補足説明・タイムスタンプに使う
    static let textSub = Color("TextSub")

    // MARK: - その他

    /// 罫線: #2A2A38 — セパレーター(区切り線)に使う。細め・控えめに
    static let separator = Color("Separator")
}

// 動作確認用のプレビュー。
// 8色すべてを一覧表示します。カラーセットの登録がまだの色は
// 真っ白(または透明)で表示されるので、登録漏れのチェックにも使えます。
#Preview {
    // 色の名前と定数のペアの一覧(プレビュー表示用)
    let palette: [(name: String, color: Color)] = [
        ("BgBase #12121A", .bgBase),
        ("BgCard #1C1C28", .bgCard),
        ("BgSpecial #0D0D13", .bgSpecial),
        ("AccentMain #8B7FD1", .accentMain),
        ("AccentSub #D4A574", .accentSub),
        ("TextMain #E8E6F0", .textMain),
        ("TextSub #8A8798", .textSub),
        ("Separator #2A2A38", .separator)
    ]

    return VStack(spacing: 10) {
        ForEach(palette, id: \.name) { entry in
            HStack {
                // 色見本(角丸の四角)
                RoundedRectangle(cornerRadius: 6)
                    .fill(entry.color)
                    .frame(width: 44, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                    )
                Text(entry.name)
                Spacer()
            }
        }
    }
    .padding()
    .background(Color.black)  // 暗い背景の上で色味を確認
    .foregroundStyle(.white)
}
