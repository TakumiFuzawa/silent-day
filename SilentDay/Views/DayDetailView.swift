//
//  DayDetailView.swift
//  SilentDay
//
//  日別詳細画面(S-05)。カレンダーで日付をタップすると表示され、
//  「その日、どの不安が穏やかに終わったか」を一覧します(F-07対応)。
//

import SwiftUI
import SwiftData

struct DayDetailView: View {

    // 表示対象の日付
    private let date: Date

    // その日のログ(画面表示時に読み込む)。
    // nilの間は「読み込み前」または「ログなし」を意味します
    @State private var log: PeacefulLog?

    // ログの取得に使うRepository
    private let logRepository: LogRepository

    init(context: ModelContext, date: Date) {
        self.date = date
        self.logRepository = LogRepository(context: context)
    }

    var body: some View {
        ZStack {
            Color.bgBase
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {

                // --- 日付の見出し(例: 7月5日) ---
                Text(dateTitle)
                    .font(.ritualTitle)
                    .foregroundStyle(Color.textMain)
                    .fadeIn()

                Text("この日、穏やかに終わった心配ごと")
                    .font(.bodySub)
                    .foregroundStyle(Color.textSub)

                // --- 完了した不安の一覧 ---
                if let log {
                    ScrollView {
                        LazyVStack(spacing: 10) {  // カード間の余白10pt(仕様書5.3)
                            ForEach(log.completedWorryTexts, id: \.self) { text in
                                HStack(spacing: 12) {
                                    // 完了マーク(仕様書5.1: AccentSubを使う)
                                    Image(systemName: "checkmark.circle")
                                        .foregroundStyle(Color.accentSub)
                                    Text(text)
                                        .font(.bodyMain)
                                        .foregroundStyle(Color.textMain)
                                    Spacer()
                                }
                                .padding(16)
                                .background(Color.bgCard)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                } else {
                    // ログが見つからない場合(通常はカレンダーのマーカーからしか
                    // 遷移しないため起きないはずですが、念のための表示)
                    Text("この日の記録はありません。")
                        .poeticStyle()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        // 画面表示時にその日のログを読み込む。
        // try? は「失敗したらnilにする」書き方(失敗時は「記録なし」表示になる)
        .onAppear {
            log = try? logRepository.fetch(for: date)
        }
    }

    // 見出し用の日付テキスト(例: 7月5日 土曜日)
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date)
    }
}

// 動作確認用のプレビュー
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    // 今日のログをサンプル登録
    let today = Calendar.current.startOfDay(for: Date())
    let log = PeacefulLog(
        date: today,
        completedWorryTexts: ["明日のプレゼンが心配", "健康診断の結果が気になる"]
    )
    context.insert(log)

    return NavigationStack {
        DayDetailView(context: context, date: today)
    }
    .modelContainer(container)
}
