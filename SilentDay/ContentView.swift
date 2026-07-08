//
//  ContentView.swift
//  SilentDay
//
//  アプリのルート(一番外側)となる画面です。
//  ホーム画面(S-01)とカレンダー画面(S-04)を下部のタブバーで切り替えます。
//  (仕様書セクション2の画面遷移「タブ切替」に対応)
//

import SwiftUI
import SwiftData

// タップされた通知の情報をまとめて持つための小さな入れ物(構造体)です。
//
// fullScreenCover(item:)で画面を表示するには、渡すデータが
// Identifiable(idを持つ型)である必要があるため、この形にしています。
// 「idが変わる=新しい通知が来た」とSwiftUIが判断して画面を出し直してくれます。
struct TappedNotificationInfo: Identifiable {
    let id = UUID()        // fullScreenCover用の一意なID
    let message: String    // 画面に表示する通知の文言
    let worryID: String?   // どのWorryItemの通知か(将来、詳細表示などに使える)
}

struct ContentView: View {

    // SilentDayApp.swiftの .modelContainer(...) で注入されたSwiftDataの窓口を
    // 環境(Environment)から受け取ります。
    // これを各画面のinit(context:)に渡すことで、全画面が同じデータベースを共有します。
    @Environment(\.modelContext) private var modelContext

    // タップされた通知の情報。
    // nil = 何も表示しない / 値が入る = NotificationDetailView(S-03)を全画面表示
    @State private var tappedNotification: TappedNotificationInfo?

    // タブバーの見た目はSwiftUIだけでは細かく指定できないため、
    // UIKit(SwiftUI以前からある仕組み)のUITabBarAppearanceを使って設定します。
    // initはこのViewが作られるときに1回だけ実行されます。
    init() {
        let appearance = UITabBarAppearance()

        // 「不透明な背景」で初期化(スクロール内容がタブバーに透けるのを防ぐ)
        appearance.configureWithOpaqueBackground()

        // タブバーの背景色をカード背景色に合わせる(仕様書5.1: BgCard)
        // UIColor(Color.○○) で、SwiftUIの色をUIKitの色に変換できます
        appearance.backgroundColor = UIColor(Color.bgCard)

        // 非選択タブのアイコン色・文字色をサブテキスト色にする
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textSub)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.textSub)
        ]

        // 通常時と、スクロールで最下部に達したとき(scrollEdge)の両方に適用。
        // scrollEdge側を設定しないと、画面によってタブバーが透明になってしまいます
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        // TabViewは「下部タブバーで画面を切り替える」コンテナです
        TabView {

            // --- タブ1: ホーム画面(S-01) ---
            HomeView(context: modelContext)
                // tabItemで「タブバーに表示するアイコンと文字」を指定します
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }

            // --- タブ2: カレンダー画面(S-04) ---
            CalendarView(context: modelContext)
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }
        }
        // tintは「選択中タブ」のアイコン・文字の色(仕様書5.1: AccentMain)
        .tint(Color.accentMain)
        // --- 通知タップイベントの受信(NotificationServiceとの接続) ---
        // NotificationServiceのdidReceive(通知タップ時)が
        // NotificationCenter.default.post で放送したイベントをここで受け取ります。
        // アプリのルート(ContentView)で受けることで、
        // どのタブを開いていてもS-03を表示できます。
        .onReceive(NotificationCenter.default.publisher(for: .didTapWorryNotification)) { notification in
            // userInfo(通知に添付されたおまけデータ)から文言とIDを取り出します。
            // 「as? String」は「Stringとして取り出せたら使う」という安全な変換です。
            // 万一文言が取り出せなくても、フォールバックの一文を表示して
            // 真っ白な画面にならないようにしています
            let message = notification.userInfo?["message"] as? String
                ?? "静かな時間が続いています。"
            let worryID = notification.userInfo?["worryID"] as? String

            // 値をセットすると、下のfullScreenCoverが反応して画面が表示されます
            tappedNotification = TappedNotificationInfo(message: message, worryID: worryID)
        }
        // --- 通知詳細画面(S-03)の全画面表示 ---
        // fullScreenCoverはsheetと違い「画面全体を覆う」表示方法です。
        // 仕様書の画面遷移「通知タップ時 → S-03を全画面表示」に対応しています。
        .fullScreenCover(item: $tappedNotification) { info in
            NotificationDetailView(message: info.message)
        }
    }
}

// 動作確認用のプレビュー。
// メモリ上の一時データベースにサンプルを入れて、両タブの表示を確認できます。
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    // ホームタブ用: 経過観察中の不安を1件
    let worry = WorryItem(text: "明日のプレゼンが心配")
    worry.createdAt = Date().addingTimeInterval(-6 * 3600)  // 6時間前に登録した想定
    context.insert(worry)

    // カレンダータブ用: 昨日の穏やかな日ログを1件
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    let log = PeacefulLog(
        date: Calendar.current.startOfDay(for: yesterday),
        completedWorryTexts: ["健康診断の結果が気になる"]
    )
    context.insert(log)

    return ContentView()
        .modelContainer(container)
}
