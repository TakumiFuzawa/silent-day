# プロジェクト概要
サイレントデイ - 何も起きないことを知らせるアプリ
詳細仕様は silent_day_spec.md を参照
Swiftソースコードは SilentDay/ フォルダ内に実装する
(このCLAUDE.mdと同じ階層にSilentDay.xcodeprojがある)

# 環境
- macOS Ventura 13.7.8
- Xcode 15.2 (Build 15C500b)
- Deployment Target: iOS 17.2
- Simulator: iOS 17.2

# コーディング規約
- コメント必須、初心者にも分かる解説を含める
- カラーはColors.swift、フォントはTypography.swiftの定数を使用
- MVVM + Repositoryパターンを維持
- デザイン(色・フォント)は silent_day_spec.md セクション5を正とし、
  実装時は必ずこの値を参照する
- 実装完了時は、手動確認用のチェックリストを箇条書きで併せて提示すること

# SwiftDataの注意点(必読)
- **#Predicateマクロは使用禁止**。この環境(Xcode 15.2 / iOS 17.2)では
  #Predicateを使ったフェッチ(Bool比較を含む)で画面が真っ白になる不具合が
  実際に発生した(2026-07-08、WorryRepository.fetchActive()で確認)
- 代わりに、全RepositoryクラスでFetchDescriptorは条件なし(ソートのみ)で
  全件取得し、絞り込みはSwift側のfilter / first(where:)で行うことを標準方式とする
- 個人利用規模のデータ量のため、この方式で性能上の問題はない

