//
//  LogRepository.swift
//  SilentDay
//
//  PeacefulLog(穏やかだった日の記録)のデータ操作をまとめたRepositoryです。
//  WorryRepositoryと同じく、SwiftDataの操作をこのクラスに集約することで、
//  画面側はデータ保存の仕組みを気にせずに済みます。
//

import Foundation
import SwiftData
import SwiftUI  // ファイル末尾の #Preview で使用

// PeacefulLogのCRUD処理を担当するクラス。
final class LogRepository {

    // SwiftDataとやり取りするための窓口(WorryRepositoryと同じ役割)
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create(追加)

    // 「穏やかだった日」の記録を追加します。
    //
    // 重要ポイント: 受け取った日付は必ず startOfDay(その日の0時0分)に丸めてから
    // 保存します。PeacefulLogのdateにはユニーク制約(1日1件ルール)があるため、
    // 時刻がバラバラのまま保存すると同じ日なのに別レコード扱いになってしまうからです。
    func add(date: Date, completedWorryTexts: [String]) throws {
        let dayStart = Calendar.current.startOfDay(for: date)

        // すでに同じ日のログがあるかを確認します。
        if let existing = try fetch(for: dayStart) {
            // 既存のログがあれば、新しい不安のテキストを追記します。
            // (同じ日に複数の不安が別々のタイミングで完了するケースに対応)
            existing.completedWorryTexts.append(contentsOf: completedWorryTexts)
        } else {
            // なければ新規作成
            let log = PeacefulLog(date: dayStart, completedWorryTexts: completedWorryTexts)
            context.insert(log)
        }
        try context.save()  // 変更を確定
    }

    // MARK: - Read(取得)

    // 指定した日付のログを1件取得します。見つからなければnilを返します。
    // 日別詳細画面(S-05)で「この日は何が穏やかに終わったか」を表示する際に使います。
    //
    // ※ #Predicateマクロがこの開発環境(Xcode 15.2 / iOS 17.2)で
    //   不具合(画面が真っ白になる)を起こすため、データベース側での絞り込みは行わず、
    //   全件取得してからSwift側のfilterで探す方式にしています(WorryRepositoryと同じ方針)。
    //   個人利用規模のデータ量なら性能上の問題はありません。
    func fetch(for date: Date) throws -> PeacefulLog? {
        // 検索する側も保存時と同じルールで日単位に丸めてから比較します。
        let dayStart = Calendar.current.startOfDay(for: date)

        let all = try fetchAll()
        // ユニーク制約により該当日は最大1件しか存在しないので、
        // first(where:) = 「条件に合う最初の1件」を返せばOKです。
        return all.first(where: { $0.date == dayStart })
    }

    // すべてのログを日付の新しい順で取得します。
    // カレンダー画面(S-04)で「穏やかな日」にマーカーを付ける際に使います。
    func fetchAll() throws -> [PeacefulLog] {
        let descriptor = FetchDescriptor<PeacefulLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}

// 動作確認用のプレビュー。
// メモリ上だけの一時データベースを使い、追加→日付指定で取得、の流れを確認します。
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let repository = LogRepository(context: container.mainContext)

    // 今日の日付でログを追加(時刻付きのDate()を渡しても内部で日単位に丸められる)
    try! repository.add(date: Date(), completedWorryTexts: ["明日のプレゼンが心配"])
    try! repository.add(date: Date(), completedWorryTexts: ["健康診断の結果が気になる"])

    // 今日のログを取得(2回addしても1日1件にまとまっているはず)
    let todayLog = (try? repository.fetch(for: Date())) ?? nil

    return VStack(alignment: .leading, spacing: 8) {
        Text("今日のログ件数: \(todayLog == nil ? 0 : 1)")
        ForEach(todayLog?.completedWorryTexts ?? [], id: \.self) { text in
            Text("・\(text)")
        }
    }
    .padding()
}
