//
//  Animations.swift
//  SilentDay
//
//  アプリ全体で使う共通アニメーションの定義です(仕様書5.3の確定版に対応)。
//
//  ■ アニメーションの方針(仕様書セクション5)
//  「即時表示を避け、0.5〜1秒のフェードインを基本にする」
//  画面や要素がふわっと現れることで、静かで落ち着いた世界観を演出します。
//
//  ■ 確定値(仕様書5.3)
//  - フェードイン: .easeIn(duration: 1.0)
//  - 通知詳細画面(S-03)ではさらに .delay(0.5) を併用
//

import SwiftUI

// MARK: - アニメーション定数

// Animation型を拡張して、共通アニメーションを定数として定義します。
// 各Viewで .animation(.fadeIn, value: ...) のように使えます。
extension Animation {

    /// 標準のフェードイン: easeIn 1.0秒(仕様書5.3の確定値)
    /// easeInは「ゆっくり始まって徐々に速くなる」動き方です。
    static let fadeIn = Animation.easeIn(duration: 1.0)

    /// 遅延付きフェードイン: 0.5秒待ってからフェードイン開始
    /// 通知詳細画面(S-03)で使用。画面が開いた直後の「間」が余韻を生みます。
    static let fadeInDelayed = Animation.easeIn(duration: 1.0).delay(0.5)
}

// MARK: - フェードイン表示のViewModifier

// 「画面に現れたとき、透明→不透明にふわっと変化する」動きを
// どのViewにも1行で付けられるようにしたViewModifierです。
//
// 仕組み: 最初は opacity(透明度)0 で配置し、
// 画面に表示された瞬間(onAppear)にアニメーション付きで1に変化させます。
struct FadeInModifier: ViewModifier {
    // フェードイン開始までの待ち時間(秒)。0なら即開始
    var delay: Double

    // 現在の透明度を保持する状態変数。
    // @Stateが付いた変数が変化すると、SwiftUIが自動で画面を再描画します。
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(opacity)  // 現在の透明度を適用
            .onAppear {
                // 画面に表示されたら、1秒かけて透明度を0→1に変化させる
                withAnimation(.easeIn(duration: 1.0).delay(delay)) {
                    opacity = 1
                }
            }
    }
}

extension View {
    /// Viewをフェードインで表示する。
    ///
    /// 使用例:
    ///   Text("穏やかな一日でした")
    ///       .fadeIn()            // 標準: 1.0秒のフェードイン
    ///
    ///   Text("通知詳細のメッセージ")
    ///       .fadeIn(delay: 0.5)  // S-03用: 0.5秒待ってからフェードイン
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
}

// 動作確認用のプレビュー。
// 表示した瞬間に2つのテキストが順にふわっと現れます。
// (左上の「更新」ボタンでプレビューを再実行すると何度でも確認できます)
#Preview {
    VStack(spacing: 24) {
        Text("標準のフェードイン(1.0秒)")
            .fadeIn()

        Text("遅延付きフェードイン(0.5秒後に開始)")
            .fadeIn(delay: 0.5)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
    .foregroundStyle(.white)
}
