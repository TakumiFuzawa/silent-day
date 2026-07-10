//
//  WorryRepository.swift
//  SilentDay
//
//  WorryItem(不安リスト)のデータ操作をまとめた「Repository(リポジトリ)」です。
//
//  ■ Repositoryパターンとは?
//  データの追加・取得・削除といった処理を1つのクラスに集約する設計手法です。
//  画面側(ViewModel)は「WorryRepositoryに頼めばデータ操作ができる」とだけ
//  知っていればよく、SwiftDataの細かい書き方を知らなくて済みます。
//  将来データの保存方法が変わっても、このファイルだけ直せばOKになります。
//

import Foundation
import SwiftData
import SwiftUI    // ファイル末尾の #Preview で使用
import WidgetKit  // データ変更をウィジェットに即時反映するために使用(v1.3 STEP 6)

// WorryItemのCRUD処理を担当するクラス。
// CRUDとは Create(作成)/ Read(読み取り)/ Update(更新)/ Delete(削除)の頭文字で、
// データ操作の基本4種類のことです。
final class WorryRepository {

    // ModelContextは「SwiftDataとやり取りするための窓口」です。
    // データの追加・取得・削除はすべてこのcontextを通して行います。
    private let context: ModelContext

    // イニシャライザで外部からModelContextを受け取ります。
    // このように「必要な部品を外から渡してもらう」書き方を
    // 依存性注入(Dependency Injection)と呼び、テストしやすくなる利点があります。
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Create(追加)

    // 新しい不安を登録し、作成したWorryItemを返します。
    // 「throws」が付いている関数は、失敗する可能性があり、
    // 失敗時にはエラーを投げる(throw)ことを意味します。
    // 呼び出す側は do-catch か try? で受け取ります。
    //
    // 戻り値を返すのは、保存後に通知のスケジュール(NotificationService)へ
    // このアイテムを渡す必要があるためです。
    // @discardableResult は「戻り値を使わなくても警告を出さない」という印です。
    @discardableResult
    func add(text: String) throws -> WorryItem {
        let item = WorryItem(text: text)
        context.insert(item)   // contextに登録(この時点ではまだメモリ上)
        try context.save()     // 端末のデータベースに書き込んで確定させる
        reloadWidget()         // ウィジェットの表示件数を即時更新(v1.3 STEP 6)
        return item
    }

    // MARK: - Read(取得)

    // 登録されているすべての不安を、新しい順(登録日時の降順)で取得します。
    func fetchAll() throws -> [WorryItem] {
        // FetchDescriptorは「どんな条件で・どんな順番でデータを取ってくるか」の指示書です。
        // sortBy で createdAt の降順(reverse = 新しいものが先頭)を指定しています。
        let descriptor = FetchDescriptor<WorryItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    // まだ完了していない(経過観察中の)不安だけを取得します。
    // ※ #Predicateマクロがこの開発環境(Xcode 15.2 / iOS 17.2)で
    //   不具合を起こすため、全件取得後にSwift側でフィルタする方式にしています。
    func fetchActive() throws -> [WorryItem] {
        let all = try fetchAll()
        return all.filter { $0.isCompleted == false }
    }
    // MARK: - Update(更新)

    // 指定した不安を「穏やか認定(完了)」に更新します。
    // 24時間経過したタイミングで呼ばれる想定です。
    func markAsCompleted(_ item: WorryItem) throws {
        // SwiftDataのモデルはプロパティを書き換えるだけで変更が追跡されます。
        item.isCompleted = true
        try context.save()  // 変更を確定
        reloadWidget()      // ウィジェットの表示件数を即時更新(v1.3 STEP 6)
    }

    // MARK: - Delete(削除)

    // 指定した不安を削除します。
    // 注意: 削除時は対応するローカル通知のキャンセルも必要です(仕様書4.2)。
    // 通知のキャンセルはNotificationService側の責務なので、
    // 呼び出し元(ViewModel)で両方を呼ぶ形にします。
    func delete(_ item: WorryItem) throws {
        context.delete(item)
        try context.save()
        reloadWidget()  // ウィジェットの表示件数を即時更新(v1.3 STEP 6)
    }

    // MARK: - ウィジェットへの反映(v1.3 STEP 6 / 仕様書12.3)

    // ホーム画面のウィジェットに「データが変わったので表示を作り直して」と依頼します。
    //
    // ■ なぜRepositoryに書くのか
    // WorryItemの書き込み(追加・完了・削除)は必ずこのクラスを通るため、
    // ここに1箇所書けば、どの画面・サービスから変更されても漏れなく反映されます。
    // (ViewModelごとに書くと、将来の実装で呼び忘れる事故が起きやすい)
    //
    // ■ reloadAllTimelines()について
    // 「即時反映のお願い」であって命令ではありません。通常は数秒以内に
    // 反映されますが、最終的なタイミングはiOSが決めます(仕様書12.6)。
    // 何度連続で呼んでもiOS側でまとめて処理されるため、負荷の心配は不要です。
    private func reloadWidget() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// 動作確認用のプレビュー。
// メモリ上だけの一時的なデータベース(isStoredInMemoryOnly: true)を使うので、
// 実際の保存データを汚さずに動作を確認できます。
#Preview {
    // try! は「失敗したらクラッシュしてよい」という書き方。プレビュー用途なので許容します。
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let repository = WorryRepository(context: container.mainContext)

    // 追加 → 取得 の一連の流れを試す
    try! repository.add(text: "明日のプレゼンが心配")
    try! repository.add(text: "健康診断の結果が気になる")
    let items = (try? repository.fetchAll()) ?? []

    return List(items) { item in
        Text(item.text)
    }
}
