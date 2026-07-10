//
//  SilentDayWidget.swift
//  SilentDayWidget(Widget Extensionターゲット)
//
//  ホーム画面ウィジェット(仕様書セクション12 / v1.3 STEP 4)。
//  App Groupの共有コンテナからWorryItemを読み込み、
//  「今、何件見守っているか」をホーム画面に常時表示します。
//
//  ■ 表示内容(仕様書12.2)
//  - Small : 見守り中の件数を大きく表示(V1.3-03)
//  - Medium: 件数+最も経過時間が長い1件のタイトルと進捗(V1.3-04)
//  - 0件のときは「穏やかです」の空状態(V1.3-07)
//
//  ■ データの流れ
//  アプリ本体がApp Group共有コンテナに保存 → ウィジェットは別プロセスから
//  同じコンテナを開いて読み取り専用で利用します。
//  絞り込みは#Predicateを使わずSwift側でfilter(CLAUDE.md方針)。
//

import WidgetKit
import SwiftUI
import SwiftData

// MARK: - 1. 表示内容の1コマ(TimelineEntry)

struct SilentDayEntry: TimelineEntry {
    let date: Date                    // このコマの表示予定時刻
    let activeCount: Int              // 見守り中(未完了)の件数
    let oldestWorryText: String?      // 最も経過時間が長い不安の内容(0件ならnil)
    let oldestWorryProgress: Double   // ↑の24時間に対する進捗(0.0〜1.0)

    // プレビューやプレースホルダで使うサンプルデータ
    static let sample = SilentDayEntry(
        date: Date(),
        activeCount: 2,
        oldestWorryText: "明日のプレゼンがうまくいくか",
        oldestWorryProgress: 0.5
    )

    // 0件(穏やか)状態のサンプル
    static let empty = SilentDayEntry(
        date: Date(),
        activeCount: 0,
        oldestWorryText: nil,
        oldestWorryProgress: 0
    )
}

// MARK: - 2. スケジュール係(TimelineProvider)

struct Provider: TimelineProvider {

    // 内容が読み込まれる前に表示される「仮の姿」。
    // データベースには触れず、固定のサンプルを返すのが作法です
    func placeholder(in context: Context) -> SilentDayEntry {
        .sample
    }

    // ウィジェットギャラリーのプレビュー用の1コマ
    func getSnapshot(in context: Context, completion: @escaping (SilentDayEntry) -> Void) {
        // ギャラリー表示(context.isPreview)では実データではなくサンプルを見せる
        if context.isPreview {
            completion(.sample)
        } else {
            completion(makeEntry())
        }
    }

    // 実際のスケジュール(タイムライン)を返します。
    // 「今の1コマ」を返し、30分後にiOSへ再生成を依頼(policy: .after)することで、
    // 進捗バーと経過時間がゆっくり進んでいきます。
    // ※ 正確に30分ごとに更新される保証はありません。更新タイミングは
    //   iOSが電池残量などを考慮して決めます(仕様書12.6)
    func getTimeline(in context: Context, completion: @escaping (Timeline<SilentDayEntry>) -> Void) {
        let entry = makeEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // 共有コンテナからデータを読み込んで、表示用の1コマを組み立てます。
    private func makeEntry(at now: Date = Date()) -> SilentDayEntry {
        do {
            // --- 共有コンテナを開く(アプリ本体のSilentDayApp.swiftと同じ設定) ---
            // スキーマ(保存モデルの定義)は本体側と完全一致させる必要があります
            let schema = Schema([WorryItem.self, PeacefulLog.self])
            let configuration = ModelConfiguration(
                schema: schema,
                groupContainer: .identifier(AppGroup.id)  // 共有ファイルAppGroup.swiftの定数
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let modelContext = ModelContext(container)

            // --- 既存のRepositoryを流用してデータ取得 ---
            // (WorryRepository.swiftは両ターゲット共有にしてある)
            let repository = WorryRepository(context: modelContext)
            let activeWorries = try repository.fetchActive()

            // 「最も経過時間が長い」= createdAtが一番古い1件を探す。
            // min(by:)は「比較ルールで最小の要素」を返すメソッドです
            let oldest = activeWorries.min(by: { $0.createdAt < $1.createdAt })

            // 24時間に対する進捗(HomeViewModelのprogressと同じ計算)
            var progress = 0.0
            if let oldest {
                let elapsed = now.timeIntervalSince(oldest.createdAt)
                progress = min(max(elapsed / (24.0 * 3600), 0), 1.0)
            }

            return SilentDayEntry(
                date: now,
                activeCount: activeWorries.count,
                oldestWorryText: oldest?.text,
                oldestWorryProgress: progress
            )
        } catch {
            // 読み込みに失敗してもウィジェットをクラッシュさせず、
            // 0件(穏やか)表示に倒します。ウィジェットはエラーUIを出す場所が
            // ないため、「安全な見た目に倒す」のが定石です
            return .empty
        }
    }
}

// MARK: - 3. 見た目(View)

// サイズ(Small/Medium)によってレイアウトを切り替える親View
struct SilentDayWidgetEntryView: View {
    var entry: Provider.Entry

    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
        // iOS 17のウィジェットで必須の背景指定(ダークトーンで世界観を統一)
        .containerBackground(for: .widget) {
            Color.wBgBase
        }
    }
}

// --- Smallサイズ: 件数を大きく表示(V1.3-03) ---
struct SmallWidgetView: View {
    let entry: SilentDayEntry

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: entry.activeCount == 0 ? "moon.zzz" : "moon.stars")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color.wAccentMain)

            if entry.activeCount == 0 {
                // 空状態(V1.3-07): 見守り中のものがない=穏やか
                Text("穏やかです")
                    .font(.custom("HiraMinProN-W3", size: 15))
                    .foregroundStyle(Color.wTextMain)
            } else {
                // 件数を主役として大きく表示
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(entry.activeCount)")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.wTextMain)
                    Text("件")
                        .font(.custom("HiraMinProN-W3", size: 13))
                        .foregroundStyle(Color.wTextSub)
                }
                Text("静かに見守り中")
                    .font(.custom("HiraMinProN-W3", size: 12))
                    .foregroundStyle(Color.wTextSub)
            }
        }
    }
}

// --- Mediumサイズ: 件数+最も長く見守っている1件の詳細(V1.3-04) ---
struct MediumWidgetView: View {
    let entry: SilentDayEntry

    var body: some View {
        if entry.activeCount == 0 {
            // 空状態(V1.3-07)
            VStack(spacing: 8) {
                Image(systemName: "moon.zzz")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color.wAccentMain)
                Text("いま、預かっている心配はありません。")
                    .font(.custom("HiraMinProN-W3", size: 14))
                    .foregroundStyle(Color.wTextMain)
            }
        } else {
            HStack(spacing: 16) {
                // 左: 件数ブロック(Smallと同じ構成)
                VStack(spacing: 4) {
                    Image(systemName: "moon.stars")
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Color.wAccentMain)
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(entry.activeCount)")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(Color.wTextMain)
                        Text("件")
                            .font(.custom("HiraMinProN-W3", size: 12))
                            .foregroundStyle(Color.wTextSub)
                    }
                    Text("見守り中")
                        .font(.custom("HiraMinProN-W3", size: 11))
                        .foregroundStyle(Color.wTextSub)
                }

                // 中央の区切り線(控えめに)
                Rectangle()
                    .fill(Color.wSeparator)
                    .frame(width: 1)
                    .padding(.vertical, 8)

                // 右: 最も経過時間が長い1件のタイトル+進捗バー
                VStack(alignment: .leading, spacing: 8) {
                    Text("いちばん長く見守っているのは")
                        .font(.custom("HiraMinProN-W3", size: 10))
                        .foregroundStyle(Color.wTextSub)

                    Text(entry.oldestWorryText ?? "")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.wTextMain)
                        .lineLimit(2)  // 長文でも2行までに抑える

                    // 24時間の進捗バー(HomeViewのカードと同じ構成)
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.wSeparator)
                            Capsule()
                                .fill(Color.wAccentMain)
                                .frame(width: geometry.size.width * entry.oldestWorryProgress)
                        }
                    }
                    .frame(height: 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - ウィジェット用の色定義

// アプリ本体のColors.swiftはAssets.xcassetsのカラーセット(アプリターゲット専用)を
// 参照しているため、ウィジェットでは仕様書5.1の値を直接定義しています。
// 頭の「w」はwidgetの意味で、本体の定数(Color.bgBase等)との混同を防ぐ命名です
private extension Color {
    static let wBgBase = Color(red: 0x12 / 255, green: 0x12 / 255, blue: 0x1A / 255)      // #12121A
    static let wAccentMain = Color(red: 0x8B / 255, green: 0x7F / 255, blue: 0xD1 / 255)  // #8B7FD1
    static let wTextMain = Color(red: 0xE8 / 255, green: 0xE6 / 255, blue: 0xF0 / 255)    // #E8E6F0
    static let wTextSub = Color(red: 0x8A / 255, green: 0x87 / 255, blue: 0x98 / 255)     // #8A8798
    static let wSeparator = Color(red: 0x2A / 255, green: 0x2A / 255, blue: 0x38 / 255)   // #2A2A38
}

// MARK: - ウィジェット本体の定義

struct SilentDayWidget: Widget {
    let kind: String = "SilentDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            SilentDayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("サイレントデイ")
        .description("静かな見守りの様子を表示します")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// 動作確認用のプレビュー。
// 通常状態(2件見守り中)と空状態(穏やか)の両方を確認できます
#Preview(as: .systemSmall) {
    SilentDayWidget()
} timeline: {
    SilentDayEntry.sample
    SilentDayEntry.empty
}

#Preview(as: .systemMedium) {
    SilentDayWidget()
} timeline: {
    SilentDayEntry.sample
    SilentDayEntry.empty
}
