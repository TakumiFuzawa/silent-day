//
//  AppGroup.swift
//  SilentDay
//
//  アプリ本体とウィジェットが共有するデータ領域(App Group)のIDです。
//
//  ■ このファイルは「両ターゲット共有」です
//  Target Membershipで SilentDay(本体)と SilentDayWidgetExtension の
//  両方に含めています。IDの文字列を1箇所にまとめることで、
//  本体とウィジェットで違うIDを書いてしまう事故を防ぎます。
//  ※ Signing & Capabilitiesで両ターゲットに設定したApp Group IDと
//    完全一致している必要があります。
//

import Foundation

enum AppGroup {
    /// App GroupのID(Signing & Capabilitiesの設定値と同じもの)
    static let id = "group.com.test.SilentDay"
}
