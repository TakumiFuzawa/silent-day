//
//  HomeView.swift
//  SilentDay
//
//  ホーム画面(S-01)。登録中の不安リストと経過時間を表示します。
//
//  ■ 画面構成(仕様書セクション2)
//  - 上部: 日付+「今日も静かな一日です」の見出し(游明朝系の明朝体)
//  - 中央: 経過観察中の不安をカード形式で縦に並べる(24時間進捗バー付き)
//  - 右下: 円形の追加ボタン(→ AddWorryView / S-02 へ)
//
//  ■ デザイン(仕様書セクション5)
//  色は Colors.swift、フォントは Typography.swift の定数のみを使用しています。
//

import SwiftUI
import SwiftData

struct HomeView: View {

    // この画面の頭脳(ViewModel)。
    // @State を付けることで、SwiftUIが画面の生存期間中ずっと同じインスタンスを
    // 保持してくれます(再描画のたびに作り直されるのを防ぐ)。
    @State private var viewModel: HomeViewModel

    // 追加画面(S-02)をsheet表示するかどうかのフラグ。
    // trueになるとAddWorryViewが下からスライドして表示されます。
    @State private var isShowingAddSheet = false

    // AddWorryViewに渡すために、受け取ったModelContextを保持しておきます
    private let context: ModelContext

    // イニシャライザでModelContext(SwiftDataの窓口)を受け取り、ViewModelを組み立てます。
    init(context: ModelContext) {
        self.context = context
        _viewModel = State(initialValue: HomeViewModel(context: context))
    }

    var body: some View {
        // ZStackは「奥から手前へ」Viewを重ねるコンテナ。
        // 一番奥に背景色、その上にメインコンテンツ、一番手前に追加ボタンを重ねます。
        ZStack(alignment: .bottomTrailing) {

            // --- 背景(画面全体) ---
            Color.bgBase
                .ignoresSafeArea()

            // --- メインコンテンツ ---
            // TimelineViewは「一定間隔で中身を再描画してくれる」コンテナです。
            // 進捗バーと経過時間表示を60秒ごとに自動更新するために使っています。
            TimelineView(.periodic(from: .now, by: 60)) { timeline in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // 上部の見出しエリア
                        headerArea

                        // 不安カードの一覧(または空のときのメッセージ)
                        if viewModel.worries.isEmpty {
                            emptyStateArea
                        } else {
                            // カードを縦に並べる。spacing: 10 はカード間の余白(仕様書5.3)
                            LazyVStack(spacing: 10) {
                                ForEach(viewModel.worries) { item in
                                    WorryCardView(
                                        item: item,
                                        progress: viewModel.progress(of: item, at: timeline.date),
                                        elapsedText: viewModel.elapsedText(of: item, at: timeline.date)
                                    )
                                    // 長押しメニューから削除できるようにする(F-02)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.delete(item)
                                        } label: {
                                            Label("削除", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)  // 画面左右の余白(仕様書5.3: 16-20pt)
                    .padding(.top, 24)
                }
            }

            // --- 右下の追加ボタン(手前に重なる) ---
            addButton
                .padding(.trailing, 20)
                .padding(.bottom, 24)
        }
        // 画面が表示されたタイミングでデータを読み込む
        .onAppear {
            viewModel.loadWorries()
        }
        // --- 追加画面(S-02)のsheet表示 ---
        .sheet(isPresented: $isShowingAddSheet, onDismiss: {
            viewModel.loadWorries()
        }) {
            AddWorryView(context: context)
        }
    }

    // MARK: - 上部の見出しエリア

    private var headerArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 今日の日付(例: 7月7日 月曜日)。控えめにサブテキスト色で表示
            Text(todayText)
                .font(.bodySub)
                .foregroundStyle(Color.textSub)

            // 世界観の見出し。明朝体でこのアプリのトーンを伝える
            Text("今日も、静かな一日です")
                .font(.ritualTitle)
                .foregroundStyle(Color.textMain)
        }
        .fadeIn()  // ふわっと表示(Animations.swiftで定義した共通モディファイア)
    }

    // 今日の日付を「7月7日 月曜日」の形式で返す
    private var todayText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: Date())
    }

    // MARK: - 不安が1件もないときの表示(空状態)

    private var emptyStateArea: some View {
        VStack(spacing: 12) {
            Text("いま、預かっている心配はありません。")
                .poeticStyle()
            Text("右下のボタンから、気がかりなことを登録できます")
                .font(.bodySub)
                .foregroundStyle(Color.textSub)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .fadeIn(delay: 0.3)
    }

    // MARK: - 右下の円形追加ボタン

    private var addButton: some View {
        Button {
            // フラグをtrueにすると、bodyの.sheetモディファイアが反応して
            // AddWorryView(S-02)が下からスライド表示されます
            isShowingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(Color.textMain)
                .frame(width: 56, height: 56)
                .background(Color.accentMain)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
        }
        .accessibilityLabel("不安を追加")
    }
}

// MARK: - 不安カード(1件分)

struct WorryCardView: View {
    let item: WorryItem
    let progress: Double
    let elapsedText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Text(item.text)
                .font(.bodyMain)
                .foregroundStyle(Color.textMain)

            Text(elapsedText)
                .font(.bodySub)
                .foregroundStyle(Color.textSub)

            // --- 24時間の進捗バー ---
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.separator)
                    Capsule()
                        .fill(Color.accentMain)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// 動作確認用のプレビュー。
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let sample1 = WorryItem(text: "明日のプレゼンが心配")
    sample1.createdAt = Date().addingTimeInterval(-3 * 3600)
    let sample2 = WorryItem(text: "健康診断の結果が気になる")
    sample2.createdAt = Date().addingTimeInterval(-12 * 3600)
    let sample3 = WorryItem(text: "送ったメールの返事がまだ来ない")
    sample3.createdAt = Date().addingTimeInterval(-30 * 60)
    context.insert(sample1)
    context.insert(sample2)
    context.insert(sample3)

    return HomeView(context: context)
        .modelContainer(container)
}
