//
//  CalendarView.swift
//  SilentDay
//
//  カレンダー画面(S-04)。過去の「穏やかだった日」を月表示で振り返ります。
//
//  ■ 画面構成(仕様書セクション2)
//  - 上部: 「穏やかだった記録」の見出し(明朝体)
//  - 中央: 月表示カレンダー(LazyVGridで7列)。ログのある日にマーカー
//  - 下部: 「今月、○日が穏やかでした」の集計テキスト
//  - 日付タップ → 日別詳細画面(S-05)へ遷移
//

import SwiftUI
import SwiftData

struct CalendarView: View {

    @State private var viewModel: CalendarViewModel

    // 日別詳細画面(S-05)に渡すために保持しておく
    private let context: ModelContext

    // 曜日ヘッダーの表示文字(日曜始まり)
    private let weekdaySymbols = ["日", "月", "火", "水", "木", "金", "土"]

    // 7列のグリッド定義。GridItem(.flexible())を7つ並べると
    // 「画面幅を7等分した列」になります(カレンダーの1週間分)。
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    init(context: ModelContext) {
        self.context = context
        _viewModel = State(initialValue: CalendarViewModel(context: context))
    }

    var body: some View {
        // NavigationStackで包むことで、日付タップ時にS-05へ「押して進む」遷移ができます
        NavigationStack {
            ZStack {
                Color.bgBase
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {

                    // --- 上部見出し(明朝体) ---
                    Text("穏やかだった記録")
                        .font(.ritualTitle)
                        .foregroundStyle(Color.textMain)
                        .fadeIn()

                    // --- 月の切り替えバー(前月 / 今月表示 / 翌月) ---
                    monthSwitcher

                    // --- 曜日ヘッダー(日〜土) ---
                    LazyVGrid(columns: columns) {
                        ForEach(weekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.bodySub)
                                .foregroundStyle(Color.textSub)
                        }
                    }

                    // --- カレンダー本体(7列グリッド) ---
                    LazyVGrid(columns: columns, spacing: 12) {
                        // daysInMonthは[Date?]なので、nil(月初前の空きマス)も含まれます。
                        // ForEachにはid が必要ですが Date? はそのまま使えないため、
                        // enumerated()で「何番目か(offset)」をidとして使っています。
                        ForEach(Array(viewModel.daysInMonth.enumerated()), id: \.offset) { _, day in
                            if let day {
                                dayCell(for: day)
                            } else {
                                // 空きマス(月初前)。何も表示しないが、マスの位置は確保する
                                Color.clear
                                    .frame(height: 44)
                            }
                        }
                    }

                    Spacer()

                    // --- 下部の集計テキスト ---
                    Text("今月、\(viewModel.peacefulCountInDisplayedMonth)日が穏やかでした")
                        .poeticStyle()  // 明朝体W3+行間広め
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 16)
                        .fadeIn(delay: 0.3)
                }
                .padding(.horizontal, 20)  // 画面左右の余白(仕様書5.3)
                .padding(.top, 24)
            }
            // 画面表示時にログを読み込む
            .onAppear {
                viewModel.loadLogs()
            }
        }
    }

    // MARK: - 月の切り替えバー

    private var monthSwitcher: some View {
        HStack {
            // 前月へ
            Button {
                viewModel.moveMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.textSub)
                    .frame(width: 44, height: 44)  // タップしやすい領域を確保
            }
            .accessibilityLabel("前の月へ")

            Spacer()

            // 表示中の月(例: 2026年7月)
            Text(viewModel.monthTitle)
                .font(.ritualHeadline)
                .foregroundStyle(Color.textMain)

            Spacer()

            // 翌月へ
            Button {
                viewModel.moveMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.textSub)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("次の月へ")
        }
    }

    // MARK: - 日付マス(1日分)

    // @ViewBuilderは「条件によって違う種類のViewを返す関数」を書くための印です
    @ViewBuilder
    private func dayCell(for day: Date) -> some View {
        // その日の「日」の数字(例: 15)
        let dayNumber = Calendar.current.component(.day, from: day)

        if viewModel.isPeaceful(day) {
            // --- 穏やかな日: マーカー付き+タップでS-05へ遷移 ---
            // NavigationLinkは「タップすると指定した画面へ進む」ボタンです
            NavigationLink {
                DayDetailView(context: context, date: day)
            } label: {
                Text("\(dayNumber)")
                    .font(.bodyMain)
                    .foregroundStyle(Color.bgBase)  // マーカーの上では暗い色の文字が読みやすい
                    .frame(width: 40, height: 40)
                    // 穏やかな日のマーカー(仕様書5.1: アクセント(サブ)= AccentSub)
                    .background(Circle().fill(Color.accentSub))
            }
            .accessibilityLabel("\(dayNumber)日 穏やかだった日")
            .frame(height: 44)
        } else {
            // --- 記録のない日: 数字のみ(タップ不可) ---
            Text("\(dayNumber)")
                .font(.bodyMain)
                // 今日だけ少し明るい文字色にして現在位置を分かりやすくする
                .foregroundStyle(viewModel.isToday(day) ? Color.accentMain : Color.textSub)
                .frame(width: 40, height: 40)
                .frame(height: 44)
        }
    }
}

// 動作確認用のプレビュー。
// 数日分のPeacefulLogをサンプル登録して、マーカー表示と集計を確認します。
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let calendar = Calendar.current

    // 「今日」「3日前」「5日前」を穏やかな日として登録
    for daysAgo in [0, 3, 5] {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let log = PeacefulLog(
            date: calendar.startOfDay(for: date),
            completedWorryTexts: ["サンプルの不安(\(daysAgo)日前)"]
        )
        context.insert(log)
    }

    return CalendarView(context: context)
        .modelContainer(container)
}
