//
//  CalendarViewModel.swift
//  SilentDay
//
//  カレンダー画面(S-04)のViewModelです。
//  「表示中の月」の管理と、穏やかな日ログの読み込み・集計を担当します。
//

import Foundation
import SwiftData
import Observation

@Observable
final class CalendarViewModel {

    // ログの取得はRepositoryに任せる
    private let logRepository: LogRepository

    // 日付計算に使うカレンダー(グレゴリオ暦、端末のタイムゾーン)
    private let calendar = Calendar.current

    // MARK: - 画面が参照する状態

    // いま表示している月(その月の1日を保持する)。
    // 例: 2026年7月を表示中なら「2026-07-01」が入っている
    var displayedMonth: Date

    // 「穏やかな日」の集合(すべてstartOfDayに丸めた日付)。
    // Setにしているのは「この日付は含まれる?」の判定(contains)が高速なためです。
    var peacefulDays: Set<Date> = []

    // エラー表示用メッセージ
    var errorMessage: String?

    // MARK: - 初期化

    init(context: ModelContext) {
        self.logRepository = LogRepository(context: context)
        // 初期表示は「今月」。今日の日付から月の初日を求める
        let now = Date()
        self.displayedMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
    }

    // MARK: - データ読み込み

    // 全ログを読み込み、「穏やかな日」の集合を作り直します。画面表示時に呼びます。
    // (CLAUDE.mdの方針どおり全件取得のみ。月単位の絞り込みもSwift側で行います)
    func loadLogs() {
        do {
            let logs = try logRepository.fetchAll()
            // map で日付だけの配列にし、Set にまとめる
            // (保存時にstartOfDayへ丸め済みだが、念のためここでも丸めて確実にする)
            peacefulDays = Set(logs.map { calendar.startOfDay(for: $0.date) })
        } catch {
            errorMessage = "記録の読み込みに失敗しました"
        }
    }

    // MARK: - 月の移動

    // 表示月を前後に動かします。value: -1 で前月、+1 で翌月
    func moveMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    // MARK: - カレンダー表示用の計算

    // 見出しに表示する「2026年7月」のようなテキスト
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: displayedMonth)
    }

    // カレンダーのマス目に並べる日付の配列を作ります。
    //
    // 戻り値が [Date?](オプショナルの配列)なのがポイントです。
    // カレンダーは日曜始まりの7列なので、月の1日が水曜なら
    // 先頭に3つの「空きマス」が必要になります。その空きマスを nil で表現します。
    // 例: 7月1日が水曜の場合 → [nil, nil, nil, 7/1, 7/2, 7/3, 7/4, 7/5, ...]
    var daysInMonth: [Date?] {
        // その月の期間(1日〜末日)を取得
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else {
            return []
        }
        let firstDay = monthInterval.start

        // 1日の曜日を取得(1=日曜, 2=月曜, ... 7=土曜)
        let firstWeekday = calendar.component(.weekday, from: firstDay)

        // 先頭の空きマスの数(日曜始まりなら「曜日番号 - 1」個)
        var days: [Date?] = Array(repeating: nil, count: firstWeekday - 1)

        // その月の日数(例: 7月なら31)
        let dayCount = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 0

        // 1日ずつDateを作って追加していく
        for offset in 0..<dayCount {
            days.append(calendar.date(byAdding: .day, value: offset, to: firstDay))
        }
        return days
    }

    // その日が「穏やかな日」(ログあり)かどうかを判定します。マーカー表示に使います。
    func isPeaceful(_ date: Date) -> Bool {
        peacefulDays.contains(calendar.startOfDay(for: date))
    }

    // その日が「今日」かどうか(今日のマスを少し目立たせるために使う)
    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    // 表示中の月に含まれる「穏やかな日」の数。
    // 下部の「今月、○日が穏やかでした」の集計に使います。
    var peacefulCountInDisplayedMonth: Int {
        peacefulDays.filter { day in
            calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
        }.count
    }
}
