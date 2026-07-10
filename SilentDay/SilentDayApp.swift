import SwiftUI
import SwiftData

// ※ App GroupのID定数は、ウィジェットとも共有するため
//   AppGroup.swift(両ターゲット共有ファイル)に移動しました(v1.3 STEP 4)

@main
struct SilentDayApp: App {

    // オンボーディング(S-06)を見終わったかどうかのフラグ。
    // @AppStorageはUserDefaults(端末に残る小さな設定保存領域)と自動同期するので、
    // アプリを終了・再起動しても値が保持されます。
    // 初回起動時はまだ保存された値がないため、初期値のfalseになります。
    // ※ OnboardingView側と同じキー文字列("hasCompletedOnboarding")を使うことで
    //   同じ保存場所を読み書きしています
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // MARK: - 共有ModelContainer(v1.3 STEP 3 / 仕様書12.3)

    // SwiftDataの保存先を「App Groupの共有コンテナ」に向けたModelContainerです。
    //
    // これまでの .modelContainer(for: [...]) はアプリ専用領域(サンドボックス内)に
    // データベースファイルを作る書き方でした。それだと別プロセスで動く
    // ウィジェットからデータが読めないため、本体・ウィジェットの両方から
    // アクセスできる共有領域に保存先を変更します。
    //
    // 【重要】保存先が変わるため、これまでアプリ専用領域に保存されていた
    // 既存データは新しいコンテナからは見えなくなります(ファイル自体は残りますが
    // 参照されなくなる)。開発中のテストデータのため移行処理は行わない判断です。
    // 詳細はREADME/コミットメッセージ参照。
    private let sharedModelContainer: ModelContainer = {
        // Schema = 「このデータベースにはどのモデルを保存するか」の定義
        let schema = Schema([WorryItem.self, PeacefulLog.self])

        // ModelConfiguration = データベースの保存方法の設定。
        // groupContainer: .identifier(...) を指定すると、SwiftDataが
        // App Groupの共有コンテナ内にデータベースファイルを作ってくれます。
        // (自分でファイルパスを組み立てる必要はありません)
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(AppGroup.id)
        )

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // コンテナが作れない=アプリとして何もできない状態なので、
            // 原因(entitlementsの設定漏れ等)をエラーメッセージ付きで即座に知らせる
            fatalError("共有ModelContainerの作成に失敗しました: \(error)")
        }
    }()

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
        // 共有コンテナをアプリ全体に注入する。
        // 各画面の @Environment(\.modelContext) の使い方はこれまでと変わりません
        .modelContainer(sharedModelContainer)
    }
}
