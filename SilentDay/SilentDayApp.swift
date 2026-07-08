import SwiftUI
import SwiftData   // ← 追加が必要

@main
struct SilentDayApp: App {

    // オンボーディング(S-06)を見終わったかどうかのフラグ。
    // @AppStorageはUserDefaults(端末に残る小さな設定保存領域)と自動同期するので、
    // アプリを終了・再起動しても値が保持されます。
    // 初回起動時はまだ保存された値がないため、初期値のfalseになります。
    // ※ OnboardingView側と同じキー文字列("hasCompletedOnboarding")を使うことで
    //   同じ保存場所を読み書きしています
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // NotificationServiceをdelegateとして登録し、通知機能を有効化する
        NotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            // 初回起動判定の分岐:
            // - まだオンボーディングを見ていない(false)→ OnboardingView(S-06)
            // - 見終わっている(true)→ ContentView(タブ画面)
            // OnboardingViewの「始める」ボタンでフラグがtrueになると、
            // @AppStorageの変化をSwiftUIが検知して、自動でContentViewに切り替わります
            if hasCompletedOnboarding {
                ContentView()
            } else {
                OnboardingView()
            }
        }
        // SwiftDataのモデルコンテナをアプリ全体に注入する
        // これがあることで、どの画面からも@Environment(\.modelContext)でアクセスできる
        .modelContainer(for: [WorryItem.self, PeacefulLog.self])
    }
}
