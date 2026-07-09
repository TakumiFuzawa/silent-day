//
//  SilentDayWidget.swift
//  SilentDayWidget(Widget Extensionターゲット)
//
//  ホーム画面ウィジェット(仕様書セクション12 / v1.3)。
//
//  ■ v1.3 STEP 1 の範囲(仕様書12.4)
//  このコードは「ウィジェットが追加でき、ビルドが通り、ホーム画面に表示できる」
//  ことだけを目標にした最小構成です。
//  アプリ本体のデータ(WorryItem等)にはまだ一切アクセスしません。
//  App Groups / SwiftData共有は STEP 2以降 で対応します。
//
//  ■ ウィジェットの登場人物(3つ)
//  1. TimelineEntry : 「ある時刻に表示する内容」1コマ分のデータ
//  2. TimelineProvider: 「いつ・どのEntryを表示するか」のスケジュール係
//  3. Widget(View)  : Entryを受け取って実際の見た目を描く
//

import WidgetKit
import SwiftUI

// MARK: - 1. 表示内容の1コマ(TimelineEntry)

// 今回は固定テキストを出すだけなので、必須のdate(表示予定時刻)しか持ちません。
// STEP 4以降で「見守り中の件数」などのプロパティをここに足していきます。
struct SilentDayEntry: TimelineEntry {
    let date: Date
}

// MARK: - 2. スケジュール係(TimelineProvider)

struct Provider: TimelineProvider {

    // ウィジェットギャラリーなどで内容が読み込まれる前に表示される「仮の姿」
    func placeholder(in context: Context) -> SilentDayEntry {
        SilentDayEntry(date: Date())
    }

    // ウィジェットギャラリーのプレビューなど、1コマだけ欲しいときに呼ばれる
    func getSnapshot(in context: Context, completion: @escaping (SilentDayEntry) -> Void) {
        completion(SilentDayEntry(date: Date()))
    }

    // 実際のスケジュール(タイムライン)を返す。
    // 今回は固定表示なので「今の1コマだけ・以後更新しない(.never)」を返します。
    // STEP 4以降で「1時間ごとに更新」などに変えていきます。
    func getTimeline(in context: Context, completion: @escaping (Timeline<SilentDayEntry>) -> Void) {
        let timeline = Timeline(entries: [SilentDayEntry(date: Date())], policy: .never)
        completion(timeline)
    }
}

// MARK: - 3. 見た目(View)

struct SilentDayWidgetEntryView: View {
    var entry: Provider.Entry

    // ウィジェットのサイズ(Small / Medium など)を知るための環境値。
    // 今回は同じ表示ですが、STEP 5でサイズごとにレイアウトを分ける際に使います
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(spacing: 8) {
            // アプリアイコンと同じ三日月モチーフ(SF Symbols)
            Image(systemName: "moon.stars")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(accentMain)

            // ダミーの固定テキスト(明朝体でアプリの世界観を先取り)
            Text("サイレントデイ")
                .font(.custom("HiraMinProN-W6", size: 15))
                .foregroundStyle(textMain)
        }
        // iOS 17のウィジェットは、背景をcontainerBackgroundで指定するのが必須です。
        // (指定しないと「Please adopt containerBackground API」エラーになります)
        .containerBackground(for: .widget) {
            bgBase
        }
    }

    // --- 色の定義(仕様書5.1の値を直接記述) ---
    // アプリ本体のColors.swiftはアプリターゲット専用で、
    // ウィジェットターゲットからはまだ参照できないため、
    // STEP 1では同じ値をここに直書きしています。
    // (デザインシステムの共有方法はSTEP 2以降で整理します)
    private var bgBase: Color {    // #12121A(背景ベース)
        Color(red: 0x12 / 255, green: 0x12 / 255, blue: 0x1A / 255)
    }
    private var accentMain: Color {  // #8B7FD1(アクセント)
        Color(red: 0x8B / 255, green: 0x7F / 255, blue: 0xD1 / 255)
    }
    private var textMain: Color {    // #E8E6F0(テキスト)
        Color(red: 0xE8 / 255, green: 0xE6 / 255, blue: 0xF0 / 255)
    }
}

// MARK: - ウィジェット本体の定義

struct SilentDayWidget: Widget {
    // kindはこのウィジェットの内部識別子(他と重複しなければOK)
    let kind: String = "SilentDayWidget"

    var body: some WidgetConfiguration {
        // StaticConfiguration = ユーザーが設定項目を持たない、いちばん単純な形式
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SilentDayWidgetEntryView(entry: entry)
        }
        // ウィジェットギャラリーに表示される名前と説明
        .configurationDisplayName("サイレントデイ")
        .description("静かな見守りの様子を表示します(準備中)")
        // Small / Medium の2サイズに対応(仕様書V1.3-02。Largeは任意のため未対応)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// 動作確認用のプレビュー(ウィジェット専用のプレビュー記法)。
// Xcodeのプレビューキャンバスで Small / Medium の見た目を確認できます。
#Preview(as: .systemSmall) {
    SilentDayWidget()
} timeline: {
    SilentDayEntry(date: Date())
}

#Preview(as: .systemMedium) {
    SilentDayWidget()
} timeline: {
    SilentDayEntry(date: Date())
}
