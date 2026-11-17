# macOS セットアップ

Apple Silicon の macOS を対象に、mise と Homebrew で環境を構築します。コマンドの一覧と全体の構成は [../README.md](../README.md) にあります。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、このディレクトリ (`mac/`) で一般ユーザーとして実行します。

```bash
./run.sh prepare
./run.sh bootstrap
exec zsh -l
```

`prepare` は Xcode Command Line Tools を確認し、Homebrew と mise 本体を入れます。Command Line Tools が無い場合はインストーラを起動して止まるので、完了後にもう一度実行します。

`bootstrap` で sudo が必要なのは、Touch ID で sudo を通すための `/etc/pam.d/sudo_local` の書き込みだけです。

## 役割分担

Git・curl などの基盤、GUI アプリ、フォントは Homebrew、開発 CLI は mise が担当します。mise 本体は公式スクリプトで入れるため、`brew install mise` は行いません。

## 注意点

- **初回の dry-run**: eza テーマのリポジトリがまだ無いため、全体の `--dry-run` がリンク元不足で止まることがあります。取得予定だけを見るには `mise -C mac bootstrap --only packages,repos --dry-run` を使います。
- **Dock と Finder の設定**: defaults は書き込んだだけでは反映されません。`killall Dock Finder` で反映します。状態は `mise -C mac bootstrap macos defaults status` で確認できます。
- **宣言にないパッケージの削除**: 自動では行いません。`mise -C mac bootstrap packages prune --dry-run` で対象を確認してから `mise -C mac bootstrap packages prune` を実行します。Homebrew で手動導入した formula も対象になるため、必ず dry-run を先に見ます。
- **外部リポジトリ**: eza テーマは既定ブランチに追従し、`update` で fast-forward されます。
