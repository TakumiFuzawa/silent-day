//
//  OnboardingView.swift
//  SilentDay
//
//  オンボーディング画面(S-06)。初回起動時のみ表示され、
//  4ページのスワイプでアプリの世界観と使い方を説明します。
//
//  ■ 初回起動フラグの仕組み
//  「始める」ボタンを押すと @AppStorage のフラグが true になり、
//  SilentDayApp.swift側の分岐によって以降はContentView(タブ画面)が
//  直接表示されるようになります。
//

import SwiftUI

// MARK: - 1ページ分のデータ

// 各ページの内容(アイコン・タイトル・説明文)をまとめた入れ物です。
// データとレイアウトを分けておくと、ページの追加・文言修正が簡単になります。
struct OnboardingPage {
    let icon: String      // SF Symbolsのアイコン名
    let title: String     // 明朝体で表示する見出し
    let message: String   // 説明文
}

// MARK: - オンボーディング画面本体

struct OnboardingView: View {

    // @AppStorageは「UserDefaults(端末に残る小さな設定保存領域)と
    // 自動で同期する変数」を作る仕組みです。
    // ここをtrueにすると端末に記録され、アプリを再起動しても値が残ります。
    // ※ SilentDayApp.swift側と同じキー文字列("hasCompletedOnboarding")を
    //   使うことで、同じ保存場所を読み書きします
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    // いま表示中のページ番号(0始まり)。TabViewと双方向バインディングします
    @State private var currentPage = 0

    // 4ページ分の内容
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars",
            title: "サイレントデイ",
            message: "何も起きなかったことを、\nそっとお知らせするアプリです。"
        ),
        OnboardingPage(
            icon: "square.and.pencil",
            title: "気がかりを、ひとつ",
            message: "不安なことを1行で登録します。\nそれだけで、静かな見守りが始まります。"
        ),
        OnboardingPage(
            icon: "bell",
            title: "静けさの知らせ",
            message: "時間が経つたび、\n「まだ何も起きていません」と\n通知が届きます。"
        ),
        OnboardingPage(
            icon: "calendar",
            title: "穏やかな日の記録",
            message: "24時間、何も起きなかった日は\n「穏やかな日」として\nカレンダーに残ります。"
        )
    ]

    // ページインジケーター(下部の「点々」)の色は、SwiftUIからは直接指定できないため
    // UIKitのUIPageControlの見た目設定(appearance)を使います。
    // initはこの画面が作られるとき1回だけ実行されます。
    init() {
        // 現在ページの点: アクセント色(仕様書5.1: AccentMain)
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.accentMain)
        // それ以外のページの点: サブテキスト色を薄くしたもの
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.textSub).withAlphaComponent(0.4)
    }

    var body: some View {
        ZStack {
            // 世界観に合わせ、少し暗い特別背景を使う
            Color.bgSpecial
                .ignoresSafeArea()

            // selection: $currentPage で「何ページ目を表示中か」を把握します
            TabView(selection: $currentPage) {
                // enumerated()で「ページ番号(index)」も一緒に取り出し、
                // .tag(index) でTabViewのselectionと結びつけます
                ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                    pageView(
                        for: page,
                        // 最終ページかどうか(「始める」ボタンの表示判定に使う)
                        isLastPage: index == pages.count - 1
                    )
                    .tag(index)
                }
            }
            // .page = 左右スワイプでページをめくるスタイル(下部に点々のインジケーター付き)
            .tabViewStyle(.page)
            // インジケーターの背景を常に表示(なくても動くが、点々の視認性が上がる)
            .indexViewStyle(.page(backgroundDisplayMode: .never))
        }
    }

    // MARK: - 1ページ分のレイアウト

    private func pageView(for page: OnboardingPage, isLastPage: Bool) -> some View {
        VStack(spacing: 32) {
            Spacer()

            // アイコン(大きめ・アクセント色)
            Image(systemName: page.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.accentMain)

            // 見出し(明朝体・仕様書5.2)
            Text(page.title)
                .font(.ritualTitle)
                .foregroundStyle(Color.textMain)

            // 説明文(明朝体W3+行間広め=poeticStyle、中央揃え)
            Text(page.message)
                .poeticStyle()
                .multilineTextAlignment(.center)

            Spacer()

            // --- 最終ページだけ「始める」ボタンを表示 ---
            if isLastPage {
                Button {
                    // フラグをtrueにして端末に記録。
                    // SilentDayApp.swiftがこの変化を検知して、
                    // 自動的にContentView(タブ画面)へ切り替わります
                    hasCompletedOnboarding = true
                } label: {
                    Text("始める")
                        .font(.bodyMain)
                        .foregroundStyle(Color.textMain)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentMain)
                        .clipShape(RoundedRectangle(cornerRadius: 24))  // ボタン角丸24pt(仕様書5.3)
                }
                .padding(.horizontal, 40)
                .fadeIn(delay: 0.3)  // ページ表示後、少し遅れてふわっと現れる
            } else {
                // 最終ページ以外では、ボタンと同じ高さの透明なスペースを置いて
                // ページをめくってもレイアウトがガタつかないようにする
                Color.clear
                    .frame(height: 50)
            }

            // 下部のページインジケーター(点々)と重ならないための余白
            Spacer()
                .frame(height: 60)
        }
        .padding(.horizontal, 20)
    }
}

// 動作確認用のプレビュー
#Preview {
    OnboardingView()
}
