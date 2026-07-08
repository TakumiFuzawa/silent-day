//
//  NotificationDetailView.swift
//  SilentDay
//
//  通知詳細画面(S-03)。ローカル通知をタップしたときに全画面表示され、
//  通知の文言をフェードインでゆっくり見せます。
//
//  ■ 演出の意図(仕様書セクション5)
//  この画面はアプリの世界観の中心なので、
//  - 他の画面より少し暗い専用背景(BgSpecial)
//  - 明朝体+広い行間(poeticStyle)
//  - 0.5秒の「間」をおいてから1秒かけてフェードイン
//  という組み合わせで、静かな余韻を演出します。
//

import SwiftUI

struct NotificationDetailView: View {

    // 表示する通知の文言(通知のuserInfoから取り出したもの)
    let message: String

    // この画面(fullScreenCover)を閉じるための機能
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // 通知詳細専用の、他画面より少し暗い背景(仕様書5.1: BgSpecial)
            Color.bgSpecial
                .ignoresSafeArea()

            VStack {
                Spacer()

                // --- 中央のメッセージ ---
                // poeticStyle(isLarge: true) = 明朝体W3 20pt + 行間広め(Typography.swift)
                // fadeIn(delay: 0.5) = 0.5秒待ってから1秒かけてフェードイン(Animations.swift)
                //   → 仕様書5.3の「easeIn(duration: 1.0) + delay(0.5)」に対応
                Text(message)
                    .poeticStyle(isLarge: true)
                    .multilineTextAlignment(.center)  // 複数行になったとき中央揃え
                    .padding(.horizontal, 32)
                    .fadeIn(delay: 0.5)

                Spacer()

                // --- 下部の補足テキスト(薄く控えめに) ---
                // メッセージ本文よりさらに遅れて現れることで、
                // 「読み終わった頃に、そっと出口を教える」流れにしています
                Text("タップして静かに閉じる")
                    .font(.bodySub)
                    .foregroundStyle(Color.textSub.opacity(0.7))
                    .padding(.bottom, 48)
                    .fadeIn(delay: 2.0)
            }
        }
        // contentShapeで「タップ判定の範囲」を長方形全体に広げます。
        // これがないと、背景の何もない部分はタップに反応しません
        .contentShape(Rectangle())
        // 画面のどこをタップしても閉じる
        .onTapGesture {
            dismiss()
        }
        // VoiceOver利用時にも閉じ方が伝わるようにする(仕様書NF-05)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("タップすると閉じます")
    }
}

// 動作確認用のプレビュー。
// 表示から0.5秒後にメッセージが、2秒後に補足テキストがふわっと現れます。
#Preview {
    NotificationDetailView(message: "穏やかな一日でした。\n何も起きないまま、今日が終わっていきます。")
}
