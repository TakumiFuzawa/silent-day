//
//  AddWorryView.swift
//  SilentDay
//
//  追加画面(S-02)。新しい不安を1行テキストで登録します。
//  HomeViewからsheet(下から出てくるモーダル画面)として表示されます。
//
//  ■ 画面構成(仕様書セクション2)
//  - テキスト入力欄(1行、フォーカス時にボーダーがアクセント色に変わる)
//  - 「静かに見守る」ボタン(保存+通知予約をして閉じる)
//  - キャンセルボタン(入力を破棄して閉じる)
//

import SwiftUI
import SwiftData

struct AddWorryView: View {

    // この画面のViewModel(HomeViewと同じ構成)
    @State private var viewModel: AddWorryViewModel

    // dismissは「この画面を閉じる」ための機能。
    // sheetで表示されている場合、dismiss()を呼ぶと下にスライドして閉じます。
    @Environment(\.dismiss) private var dismiss

    // @FocusStateは「どの入力欄にカーソル(フォーカス)があるか」を管理する仕組み。
    // trueのときテキスト欄にキーボードが出て、ボーダー色の切り替えにも使います。
    @FocusState private var isTextFieldFocused: Bool

    // ModelContextを受け取ってViewModelを組み立てる(HomeViewと同じ書き方)
    init(context: ModelContext) {
        _viewModel = State(initialValue: AddWorryViewModel(context: context))
    }

    var body: some View {
        // NavigationStackで包むと、上部にタイトルとツールバー(キャンセルボタン)を置けます
        NavigationStack {
            ZStack {
                // 背景色(画面全体)
                Color.bgBase
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {

                    // --- 世界観の説明テキスト ---
                    Text("気がかりなことを、ひとつ。")
                        .font(.ritualHeadline)
                        .foregroundStyle(Color.textMain)
                        .fadeIn()

                    Text("登録すると、静かに見守りが始まります。\n何も起きないまま時間が過ぎるたび、お知らせします。")
                        .font(.bodySub)
                        .foregroundStyle(Color.textSub)

                    // --- テキスト入力欄(1行) ---
                    TextField(
                        "",
                        text: $viewModel.text,
                        // promptは「未入力時に薄く表示される案内文(プレースホルダー)」
                        prompt: Text("例:明日のプレゼンがうまくいくか")
                            .foregroundStyle(Color.textSub)
                    )
                    .font(.bodyMain)
                    .foregroundStyle(Color.textMain)
                    .padding(16)
                    .background(Color.bgCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))  // 角丸12pt(仕様書5.3)
                    // overlayで枠線を重ねる。フォーカス中はアクセント色、通常時は罫線色
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isTextFieldFocused ? Color.accentMain : Color.separator,
                                lineWidth: 1
                            )
                    )
                    // この入力欄と isTextFieldFocused を紐づける
                    .focused($isTextFieldFocused)
                    // 改行キーを「完了」表示にする(1行入力なので改行は不要)
                    .submitLabel(.done)

                    // --- 「静かに見守る」ボタン ---
                    Button {
                        saveAndClose()
                    } label: {
                        Text("静かに見守る")
                            .font(.bodyMain)
                            .foregroundStyle(Color.textMain)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentMain)
                            .clipShape(RoundedRectangle(cornerRadius: 24))  // ボタン角丸24pt(仕様書5.3)
                    }
                    // 入力が空(または空白のみ)の間はボタンを無効化
                    .disabled(!viewModel.canSave)
                    // 無効時は半透明にして「押せない」ことを見た目でも伝える
                    .opacity(viewModel.canSave ? 1.0 : 0.4)

                    Spacer()  // 残りの空間を埋めて、コンテンツを上に寄せる
                }
                .padding(.horizontal, 20)  // 画面左右の余白(仕様書5.3)
                .padding(.top, 24)
            }
            // --- 上部ツールバーのキャンセルボタン ---
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        // 何も保存せずに閉じる(入力内容は破棄される)
                        dismiss()
                    }
                    .foregroundStyle(Color.textSub)
                }
            }
            // ツールバー部分も背景色に馴染ませる
            .toolbarBackground(Color.bgBase, for: .navigationBar)
        }
        // 画面が開いたら自動でテキスト欄にフォーカス(すぐ入力を始められるように)
        .onAppear {
            isTextFieldFocused = true
        }
        // エラーが起きたときのアラート表示。
        // errorMessageに値が入ると自動で表示され、OKを押すとnilに戻ります。
        .alert(
            "登録できませんでした",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // 保存処理。成功したときだけ画面を閉じます。
    // (失敗時はerrorMessageにメッセージが入り、上のalertが表示されます)
    private func saveAndClose() {
        if viewModel.save() {
            dismiss()
        }
    }
}

// 動作確認用のプレビュー
#Preview {
    let container = try! ModelContainer(
        for: WorryItem.self, PeacefulLog.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return AddWorryView(context: container.mainContext)
        .modelContainer(container)
}
