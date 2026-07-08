//
//  NotificationService.swift
//  SilentDay
//
//  ローカル通知のスケジュール管理を担当するサービスです(仕様書4.2 / F-03対応)。
//
//  ■ このクラスの役割
//  1. 通知権限のリクエスト(初回起動時にユーザーへ許可を求める)
//  2. WorryItem登録時に 6h / 12h / 24h 後の3段階の通知を予約する
//  3. WorryItem削除時に予約済みの通知をキャンセルする
//  4. 通知の受信イベント(フォアグラウンド表示・タップ)をハンドリングする
//
//  ■ 64件制約について(仕様書NF-02)
//  iOSはアプリごとに「保留中のローカル通知は最大64件」という制限があります。
//  このアプリでは 1項目=3通知 × 同時最大10件(UI側で制限)= 最大30件 に抑え、
//  制約に余裕を持たせる設計です。
//

import Foundation
import UserNotifications  // ローカル通知を扱うためのフレームワーク
import SwiftUI            // ファイル末尾の #Preview で使用

// MARK: - 通知タップイベントの名前定義

// NotificationCenter(アプリ内でイベントを放送する仕組み)で使う「イベント名」を定義します。
// ※ UNUserNotificationCenter(OSの通知)と NotificationCenter(アプリ内放送)は
//   名前が似ていますが全くの別物なので注意してください。
extension Notification.Name {
    // 「ユーザーが通知をタップした」ことをアプリ全体に知らせるためのイベント名。
    // これを受信した画面側が NotificationDetailView(S-03)を全画面表示します。
    static let didTapWorryNotification = Notification.Name("didTapWorryNotification")
}

// MARK: - NotificationService本体

// NSObjectを継承しているのは、UNUserNotificationCenterDelegateプロトコルが
// NSObjectProtocolを要求するためです(Objective-C由来の仕組みの名残)。
final class NotificationService: NSObject, UNUserNotificationCenterDelegate {

    // シングルトン(アプリ全体で1つだけのインスタンスを共有する設計)。
    // 通知のdelegate(受信係)はアプリで1つに固定する必要があるため、この形にします。
    static let shared = NotificationService()

    // 通知文言の生成はMessageGeneratorに任せます(役割分担)
    private let messageGenerator = MessageGenerator()

    // 外部からのインスタンス生成を禁止(シングルトンを強制するため)
    private override init() {
        super.init()
    }

    // MARK: - 初期設定

    // アプリ起動時に1回だけ呼び出す初期設定メソッド。
    // delegate(通知イベントの受信係)として自分自身を登録し、通知権限を求めます。
    //
    // ┌─ SilentDayApp.swift への登録コード例 ─────────────────────┐
    // │ @main                                                        │
    // │ struct SilentDayApp: App {                                   │
    // │     init() {                                                 │
    // │         // アプリ起動時に通知の受信係を登録し、権限を求める      │
    // │         NotificationService.shared.configure()               │
    // │     }                                                        │
    // │     var body: some Scene {                                   │
    // │         WindowGroup {                                        │
    // │             ContentView()                                    │
    // │                 .modelContainer(for: [WorryItem.self,        │
    // │                                       PeacefulLog.self])     │
    // │         }                                                    │
    // │     }                                                        │
    // │ }                                                            │
    // └──────────────────────────────────────────────────────────┘
    func configure() {
        // delegateを設定すると、下の方にある willPresent / didReceive が呼ばれるようになります
        UNUserNotificationCenter.current().delegate = self
        requestAuthorization()
    }

    // 通知権限をユーザーにリクエストします。
    // 拒否されてもアプリが壊れないよう、結果はログ出力のみに留めます(仕様書NF-04)。
    // 拒否時はアプリ内表示だけで完結するフォールバックUIを画面側で用意します。
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]  // 表示・音・バッジの許可を求める
        ) { granted, error in
            if let error {
                print("通知権限リクエストでエラー: \(error.localizedDescription)")
            }
            print("通知権限: \(granted ? "許可" : "拒否")")
        }
    }

    // MARK: - 通知のスケジュール(WorryItem登録時に呼ぶ)

    // 1つのWorryItemに対して、6時間後・12時間後・24時間後の3件の通知を予約します。
    func scheduleNotifications(for item: WorryItem) {
        // 「何時間後に・どの時間帯の文言で通知するか」の組み合わせを定義。
        // 通知の内容は"予約した時点"で確定するため、message(since:)ではなく
        // 「発火する時刻に合った時間帯(Phase)」を明示的に指定するのがポイントです。
        // (例: 6時間後に届く通知には、6-24h帯のやや落ち着いた文言を使う)
        let schedules: [(hours: Double, phase: MessageGenerator.Phase)] = [
            (6,  .middle),     // 6時間後 → 「半日が過ぎました」系の文言
            (12, .middle),     // 12時間後 → 同じくmiddle帯(ランダムなので文言は変わる)
            (24, .completed)   // 24時間後 → 「穏やかな一日でした」系の締めの文言
        ]

        for schedule in schedules {
            // --- 1. 通知の中身(タイトル・本文)を作る ---
            let content = UNMutableNotificationContent()
            content.title = "サイレントデイ"
            content.body = messageGenerator.message(for: schedule.phase)
            content.sound = .default

            // userInfoは「通知に添付できるおまけデータ」です。
            // タップされたとき、どのWorryItemの通知だったかを特定するために
            // IDと文言を入れておきます(didReceiveで取り出します)。
            content.userInfo = [
                "worryID": item.id.uuidString,
                "message": content.body
            ]

            // --- 2. 発火タイミング(トリガー)を作る ---
            // UNTimeIntervalNotificationTriggerは「今から○秒後」に発火するトリガー。
            // hours × 3600 で時間を秒に変換しています。
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: schedule.hours * 3600,
                repeats: false  // 繰り返さず1回だけ
            )

            // --- 3. 識別子(ID)を作る ---
            // 「WorryItemのUUID-経過時間」の形式にすることで、
            // 削除時にこのWorryItemに属する通知だけを狙ってキャンセルできます。
            // 例: "A1B2C3...-6h"
            let identifier = "\(item.id.uuidString)-\(Int(schedule.hours))h"

            // --- 4. リクエストとしてまとめてOSに予約する ---
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    print("通知スケジュール失敗(\(identifier)): \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - 通知のキャンセル(WorryItem削除時に呼ぶ)

    // 指定したWorryItemに対応する3件の通知予約を取り消します(仕様書4.2)。
    // WorryRepository.delete() と必ずセットで呼んでください(ViewModel側の責務)。
    func cancelNotifications(for item: WorryItem) {
        // スケジュール時と同じルールで識別子を組み立てて、まとめて削除します
        let identifiers = [6, 12, 24].map { "\(item.id.uuidString)-\($0)h" }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - UNUserNotificationCenterDelegate(通知イベントの受信係)

    // 【アプリを開いている最中(フォアグラウンド)に通知が届いたとき】に呼ばれます。
    // 通常、フォアグラウンド中の通知は何も表示されませんが、
    // ここで [.banner, .sound, .list] を返すことで
    // 「バナー表示・音・通知センターへの記録」をアプリ使用中でも行うようにします。
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }

    // 【ユーザーが通知をタップしたとき】に呼ばれます。
    // ここから直接画面遷移はできない(このクラスはUIを持たない)ため、
    // NotificationCenter.default.post でアプリ内に「通知がタップされたよ」と放送し、
    // それを受信した画面側が NotificationDetailView(S-03)を全画面表示します。
    //
    // ┌─ 画面側での受信コード例(ContentViewなどに書く)──────────────┐
    // │ .onReceive(NotificationCenter.default.publisher(               │
    // │     for: .didTapWorryNotification)) { notification in          │
    // │     // userInfoからタップされた通知の情報を取り出す               │
    // │     if let info = notification.userInfo,                       │
    // │        let message = info["message"] as? String {              │
    // │         // ここでNotificationDetailViewを表示する状態をtrueにする │
    // │         tappedMessage = message                                │
    // │         isShowingDetail = true                                 │
    // │     }                                                          │
    // │ }                                                              │
    // └────────────────────────────────────────────────────────────┘
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // 通知に添付しておいたおまけデータ(userInfo)を取り出す
        let userInfo = response.notification.request.content.userInfo

        // アプリ内に放送(post)。画面側はこのイベントを受信して遷移する。
        // UIに関わる処理なのでメインスレッドで実行します。
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .didTapWorryNotification,
                object: nil,
                userInfo: userInfo as? [String: Any]
            )
        }

        // 「処理が終わった」ことをOSに伝える(呼び忘れるとOSに警告される)
        completionHandler()
    }
}

// 動作確認用のプレビュー。
// ※ 通知の実際の発火はプレビューでは確認できません(シミュレータ/実機で確認)。
//   ここでは「スケジュール→保留中の件数確認→キャンセル」の流れだけ試せるようにしています。
#Preview {
    VStack(spacing: 16) {
        Text("NotificationService 動作確認")

        Button("通知権限をリクエスト") {
            NotificationService.shared.requestAuthorization()
        }

        Button("テスト用WorryItemの通知を予約") {
            let item = WorryItem(text: "プレビューのテスト不安")
            NotificationService.shared.scheduleNotifications(for: item)
            // 保留中の通知件数をコンソールに出力して確認
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                print("保留中の通知: \(requests.count)件")
                requests.forEach { print(" - \($0.identifier)") }
            }
        }
    }
    .padding()
}
