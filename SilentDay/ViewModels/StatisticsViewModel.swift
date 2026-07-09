//
//  StatisticsViewModel.swift
//  SilentDay
//
//  統計画面(S-07)のViewModelです(仕様書セクション11 / v1.2対応)。
//  蓄積されたWorryItem / PeacefulLogを読み取り専用で集計します。
//  (この画面から新規の書き込みは発生させない方針:仕様書11.4)
//

import Foundation
import SwiftData
import Observation

// MARK: - グラフ1本分のデータ

// 棒グラフの1本(=1日分)を表す入れ物です。
// Identifiableに準拠させることで、SwiftUIのChartやForEachでそのまま使えます。
struct DailyPeacefulCount: Identifiable {
    var id: Date { date }   // 日付そのものをIDとして使う(1日1本なので重複しない)
    let date: Date          // 対象の日(startOfDayに丸め済み)
    let count: Int          // その日に穏やかに終わった不安の件数(0 = 記録なし)
}

// MARK: - ViewModel本体

@Observable
final class StatisticsViewModel {

    // 集計元のデータ取得は既存Repositoryを流用(仕様書11.4)
    private let worryRepository: WorryRepository
    private let logRepository: LogRepository

    private let calendar = Calendar.current

    // MARK: - 画面が参照する状態

    // 累計の見守り件数(これまで登録されたWorryItemの総数。完了・未完了を問わない)
    var totalWorryCount = 0

    // 累計の穏やかな日数(PeacefulLogの総数 = ログが作られた日の数)
    var totalPeacefulDays = 0

    // 直近30日分のグラフ用データ(記録がない日も count 0 として必ず30個並ぶ)
    var last30Days: [DailyPeacefulCount] = []

    // エラー表示用メッセージ
    var errorMessage: String?

    // MARK: - 初期化

    init(context: ModelContext) {
        self.worryRepository = WorryRepository(context: context)
        self.logRepository = LogRepository(context: context)
    }

    // MARK: - 集計

    // 全データを読み込んで集計し直します。画面表示時に呼びます。
    // CLAUDE.mdの方針どおり、取得はfetchAll()のみで、
    // 絞り込み・集計はすべてSwift側で行っています。
    func load() {
        do {
            let allWorries = try worryRepository.fetchAll()
            let allLogs = try logRepository.fetchAll()

            // --- サマリー(累計値) ---
            totalWorryCount = allWorries.count
            totalPeacefulDays = allLogs.count

            // --- 直近30日のグラフ用データ ---
            // まず「日付 → その日の完了件数」の辞書(Dictionary)を作ります。
            // 辞書にしておくと、後の日付ごとの検索が配列より高速で簡単になります。
            var countByDay: [Date: Int] = [:]
            for log in allLogs {
                let day = calendar.startOfDay(for: log.date)
                countByDay[day] = log.completedWorryTexts.count
            }

            // 「29日前」から「今日」までの30日分を順番に作ります。
            // 記録がない日も count 0 のデータを入れることで、
            // グラフのx軸が欠けずに30日分きれいに並びます。
            let today = calendar.startOfDay(for: Date())
            last30Days = (0..<30).reversed().compactMap { daysAgo in
                guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today) else {
                    return nil
                }
                // 辞書から件数を取り出す。なければ0(?? はnilのときの代替値)
                return DailyPeacefulCount(date: day, count: countByDay[day] ?? 0)
            }
        } catch {
            errorMessage = "統計データの読み込みに失敗しました"
        }
    }

    // MARK: - 画面表示の判定用

    // データが1件もない(まだ使い始めたばかり)かどうか。
    // trueのとき、画面全体を空状態メッセージに切り替えます(仕様書V1.2-05)
    var isEmpty: Bool {
        totalWorryCount == 0 && totalPeacefulDays == 0
    }

    // 直近30日間に穏やかな記録が1日でもあるか。
    // falseのとき、グラフの代わりにミニ空状態メッセージを表示します
    var hasRecentData: Bool {
        last30Days.contains { $0.count > 0 }
    }

}
