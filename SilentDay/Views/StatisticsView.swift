//
//  StatisticsView.swift
//  SilentDay
//
//  統計画面(S-07)。蓄積されたデータを俯瞰し、達成感・安心感を提供します
//  (仕様書セクション11 / v1.2対応)。
//
//  ■ 画面構成(仕様書11.3)
//  - サマリーカード: 累計見守り件数・累計穏やかな日数
//  - 直近30日の棒グラフ(Swift Charts)
//  - データがないときは詩的な空状態メッセージ
//
//  ■ グラフのデザイン方針
//  - 単一系列なので凡例は置かない(タイトルが系列名を兼ねる)
//  - 棒はアクセント色1色(#8B7FD1)。ダーク背景とのコントラストは検証済み
//  - 目盛り線・軸ラベルは控えめな色(Separator / TextSub)にして、データを主役にする
//

import SwiftUI
import SwiftData
import Charts  // Swift Charts(iOS 16以降の標準グラフフレームワーク。追加ライブラリ不要)

struct StatisticsView: View {

    @State private var viewModel: StatisticsViewModel

    init(context: ModelContext) {
        _viewModel = State(initialValue: StatisticsViewModel(context: context))
    }

    var body: some View {
        ZStack {
            Color.bgBase
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // --- 見出し(明朝体) ---
                    Text("静けさの記録")
                        .font(.ritualTitle)
                        .foregroundStyle(Color.textMain)
                        .fadeIn()

                    if viewModel.isEmpty {
                        // データが1件もないときは、画面全体を空状態メッセージに
                        emptyStateArea
                    } else {
                        // --- サマリーカード(2枚横並び) ---
                        HStack(spacing: 10) {  // カード間の余白10pt(仕様書5.3)
                            summaryCard(
                                value: viewModel.totalWorryCount,
                                unit: "件",
                                label: "見守った心配ごと"
                            )
                            summaryCard(
                                value: viewModel.totalPeacefulDays,
                                unit: "日",
                                label: "穏やかだった日"
                            )
                        }

                        // --- 直近30日のグラフ ---
                        chartArea
                    }
                }
                .padding(.horizontal, 20)  // 画面左右の余白(仕様書5.3)
                .padding(.top, 24)
            }

        }
        // 画面表示時に集計する
        .onAppear {
            viewModel.load()
        }
        // ナビゲーションバーも背景色に馴染ませる
        .toolbarBackground(Color.bgBase, for: .navigationBar)
    }

    // MARK: - サマリーカード(1枚分)

    // 数値・単位・説明ラベルを縦に並べたカードです。
    private func summaryCard(value: Int, unit: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 数値は大きく、単位は小さく添える。
            // 数値・ラベルの文字色はテキスト用の色を使い、
            // アクセント色は「データ(グラフの棒)」のためにとっておく
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(value)")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(Color.textMain)
                Text(unit)
                    .font(.bodySub)
                    .foregroundStyle(Color.textSub)
            }
            Text(label)
                .font(.bodySub)
                .foregroundStyle(Color.textSub)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))  // カード角丸12pt(仕様書5.3)
    }

    // MARK: - 直近30日の棒グラフ

    private var chartArea: some View {
        VStack(alignment: .leading, spacing: 12) {
            // グラフのタイトル(単一系列なので、これが凡例の代わりになる)
            Text("直近30日の穏やかな記録")
                .font(.bodySub)
                .foregroundStyle(Color.textSub)

            if viewModel.hasRecentData {
                // Chart { } の中に「データ1件 → 棒1本」のルール(BarMark)を書きます
                Chart(viewModel.last30Days) { day in
                    BarMark(
                        // x軸: 日付(unit: .dayで「1日ごとの棒」として扱われる)
                        x: .value("日付", day.date, unit: .day),
                        // y軸: その日に穏やかに終わった件数
                        y: .value("件数", day.count)
                    )
                    // 棒の色はアクセント色1色(仕様書11.3)
                    .foregroundStyle(Color.accentMain)
                    // 棒の上端だけ少し丸めて、柔らかい印象にする
                    .cornerRadius(2)
                }
                // x軸: 7日ごとに「7/1」形式の日付ラベルを表示。
                // 目盛り線・ラベルは控えめな色にして、棒(データ)を主役にする
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.separator)
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(Color.textSub)
                    }
                }
                // y軸: 件数は整数なので目盛りを少なめ(最大4本)にする
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.separator)
                        AxisValueLabel()
                            .foregroundStyle(Color.textSub)
                    }
                }
                .frame(height: 200)
                .padding(16)
                .background(Color.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .fadeIn(delay: 0.3)
            } else {
                // 累計はあるが、直近30日には記録がない場合のミニ空状態
                Text("この30日は、まだ記録がありません。\nこれからの静けさが、ここに積もっていきます。")
                    .poeticStyle()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - データが1件もないときの空状態(仕様書V1.2-05)

    // 既存のHomeView.emptyStateAreaと同じトーン(詩的スタイル+補足)を踏襲
    private var emptyStateArea: some View {
        VStack(spacing: 12) {
            Text("まだ、記録は始まったばかりです。")
                .poeticStyle()
            Text("心配ごとを見守り終えると、ここに静けさが積もっていきます")
                .font(.bodySub)
                .foregroundStyle(Color.textSub)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .fadeIn(delay: 0.3)
    }

}

// 動作確認用のプレビュー。
// サンプルとして疎らな10日分のログと不安3件を登録して表示します。
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext
    let calendar = Calendar.current

    // 不安3件(累計見守り件数の確認用)
    for i in 1...3 {
        context.insert(WorryItem(text: "サンプルの不安\(i)"))
    }
    // 疎らな10日分のログ(グラフの確認用)
    for daysAgo in [1, 2, 5, 7, 8, 12, 15, 20, 24, 28] {
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: Date())!
        let log = PeacefulLog(
            date: calendar.startOfDay(for: date),
            completedWorryTexts: Array(repeating: "サンプル", count: (daysAgo % 3) + 1)
        )
        context.insert(log)
    }

    return NavigationStack {
        StatisticsView(context: context)
    }
    .modelContainer(container)
}
