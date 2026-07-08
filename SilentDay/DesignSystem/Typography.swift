//
//  Typography.swift
//  SilentDay
//
//  アプリ全体で使うフォント(文字スタイル)の定義です(仕様書5.2の確定版に対応)。
//
//  ■ 使い方のルール(仕様書5.4)
//  各Viewでは直接フォント名を書かず、必ずここの定数経由で使います。
//    ○ 良い例: .font(.ritualTitle)
//    × 悪い例: .font(.custom("HiraMinProN-W6", size: 24))
//
//  ■ フォントの方針(仕様書5.2)
//  | 用途                 | フォント                        | サイズ   |
//  |---------------------|--------------------------------|---------|
//  | 見出し・世界観テキスト  | 明朝体(HiraMinProN-W6 / 太め)   | 22-28pt |
//  | 本文・UI操作系        | San Francisco(システム標準)     | 15-17pt |
//  | 通知文言・詩的テキスト  | 明朝体(HiraMinProN-W3 / 細め)   | 17-20pt |
//
//  ※ HiraMinProN(ヒラギノ明朝 ProN)はiOSに最初から入っている明朝体なので、
//    フォントファイルの追加やInfo.plistへの登録は不要です。
//    W6は太め(見出し向き)、W3は細め(本文・詩的テキスト向き)の意味です。
//

import SwiftUI

// Fontを拡張して、独自のフォント定数を追加します(Colors.swiftと同じ考え方)。
extension Font {

    // MARK: - 見出し・世界観テキスト(明朝体・太め)

    /// 大見出し: 明朝体W6 28pt — オンボーディングの世界観テキストなど、一番大きな見出し用
    ///
    /// relativeTo: を指定すると、ユーザーが設定アプリで文字サイズを変えたとき
    /// (Dynamic Type)に合わせて自動で拡大縮小されます(仕様書NF-05対応)。
    /// 「.largeTitle相当の役割です」とOSに教えるイメージです。
    static let ritualTitleLarge = Font.custom("HiraMinProN-W6", size: 28, relativeTo: .largeTitle)

    /// 中見出し: 明朝体W6 24pt — 各画面のタイトルなど標準的な見出し用
    static let ritualTitle = Font.custom("HiraMinProN-W6", size: 24, relativeTo: .title)

    /// 小見出し: 明朝体W6 22pt — セクションの小さな見出し用
    static let ritualHeadline = Font.custom("HiraMinProN-W6", size: 22, relativeTo: .title2)

    // MARK: - 本文・UI操作系(システム標準フォント)

    /// 本文: システム標準 17pt — リスト項目のテキストなど、メインの本文用
    static let bodyMain = Font.system(size: 17)

    /// 本文(小): システム標準 15pt — 補足説明・タイムスタンプなど控えめなテキスト用
    static let bodySub = Font.system(size: 15)

    // MARK: - 通知文言・詩的テキスト(明朝体・細め)

    /// 詩的テキスト(大): 明朝体W3 20pt — 通知詳細画面(S-03)のメッセージ表示用
    static let poeticLarge = Font.custom("HiraMinProN-W3", size: 20, relativeTo: .title3)

    /// 詩的テキスト: 明朝体W3 17pt — カード内の通知文言表示などに使う
    static let poetic = Font.custom("HiraMinProN-W3", size: 17, relativeTo: .body)
}

// MARK: - 詩的テキスト用のスタイル(フォント+行間のセット)

// 仕様書5.2では詩的テキストに「行間広め」の指定があります。
// 行間(lineSpacing)はFontではなくViewに対して設定するものなので、
// 「フォント+行間+色」をまとめて適用できるViewModifierを用意しました。
//
// ViewModifierとは「Viewへの複数の装飾をひとまとめにして名前を付ける」仕組みです。
struct PoeticTextStyle: ViewModifier {
    // 大きめサイズ(通知詳細画面用)にするかどうか
    var isLarge: Bool = false

    func body(content: Content) -> some View {
        content
            .font(isLarge ? .poeticLarge : .poetic)
            .lineSpacing(10)              // 行間を広めにとって、静かな余白を演出
            .foregroundStyle(Color.textMain)
    }
}

extension View {
    /// 詩的テキストのスタイルを一括適用する。
    /// 使用例: Text("まだ静かな時間が続いています。").poeticStyle(isLarge: true)
    func poeticStyle(isLarge: Bool = false) -> some View {
        modifier(PoeticTextStyle(isLarge: isLarge))
    }
}

// 動作確認用のプレビュー。
// 各フォントスタイルの見た目を一覧で確認できます。
#Preview {
    VStack(alignment: .leading, spacing: 20) {
        Text("大見出し(W6 28pt)").font(.ritualTitleLarge)
        Text("中見出し(W6 24pt)").font(.ritualTitle)
        Text("小見出し(W6 22pt)").font(.ritualHeadline)
        Text("本文テキスト(システム 17pt)").font(.bodyMain)
        Text("補足テキスト(システム 15pt)").font(.bodySub)

        // 詩的テキストは行間込みのスタイルで確認
        Text("まだ静かな時間が続いています。\n世界は今日も穏やかなようです。")
            .poeticStyle(isLarge: true)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Color.black)  // ダークテーマ想定なので暗い背景で確認
    .foregroundStyle(.white)
}
