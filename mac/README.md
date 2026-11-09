# macOS セットアップ

Apple Silicon の macOS を対象に、mise と Homebrew で環境を構築します。Linux・Windows と同じ mise bootstrap の仕組みを使います。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、一般ユーザーで実行します。

```bash
./setup.sh prepare
./setup.sh bootstrap
exec zsh -l
```

`prepare` は Xcode Command Line Tools を確認し、Homebrew が無ければ公式スクリプトで導入し、独立した mise を `~/.local/bin/mise` に導入します。導入済みなら何もしないため、実行は初回だけで済みます。mise 本体の更新は `bootstrap --update` と共通設定の `self_update.auto` が担います。必要バージョンは 2026.11.2 以上で、`mise.toml` の `min_version` が検査します。

`bootstrap` は Homebrew パッケージ、`/etc/pam.d/sudo_local`、外部リポジトリ、dotfiles、macOS の defaults、ツール、krew プラグインの順に適用します。sudo が必要なのは `sudo_local` の書き込みだけです。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

- `mise.toml`: 必要バージョンと共通ツール設定の読み込みだけ。`mise/conf.d/*.toml` は同じディレクトリの設定として自動で読み込まれ、このファイルの trust に含まれます。
- `mise/conf.d/packages.toml`: 外部から取得するもの。Homebrew の formula (`brew:`) と cask (`brew-cask:`)、eza テーマのリポジトリ。Homebrew はバージョン固定に対応しません。
- `mise/conf.d/dotfiles.toml`: ホームに配置するシンボリックリンク。リンク元の相対パスはこのファイルの位置が基準です。
- `mise/conf.d/macos.toml`: Dock と Finder の defaults、sudo の Touch ID 設定。
- `mise/conf.d/tasks.toml`: `krew:install` タスク。`bootstrap` タスクから呼び出し、単独では `mise -C mac run krew:install` で実行できます。
- `../dotfiles/.config/mise/conf.d/mac.toml`: macOS 固有の CLI ツール。ホームにも配置され、どのディレクトリでも利用できます。
- `../dotfiles/.zprofile`、`.zshrc`: Homebrew と mise の有効化、補完、alias。
- `../dotfiles/.config/mise/config.toml`: 全 OS 共通のランタイムと CLI ツール。
- `../dotfiles/.config/mise/conf.d/settings.toml`: mise 本体の設定 (`self_update.auto`)。ホームにだけ配置し、`mise.toml` からは include しません。

ホームに配置するファイルの実体は、OS を問わずリポジトリ直下の `dotfiles/` にホームと同じ構造で置きます。どの OS が何を使うかは各 OS の `mise/conf.d/dotfiles.toml` が決めます。

Git・curl などの基盤と GUI アプリ、フォントは Homebrew、開発 CLI は mise が担当します。mise 本体は Homebrew ではなく公式スクリプトで入れるため、`brew install mise` は行いません。

## 更新と確認

```bash
./setup.sh bootstrap --dry-run
./setup.sh bootstrap --update
./setup.sh bootstrap --link-only
```

通常の適用は不足しているパッケージを導入します。`--update` は mise 本体、宣言した Homebrew パッケージ、mise ツールを更新します。eza テーマは既定ブランチに追従し、`--update` で fast-forward されます。ツールの `latest` と Homebrew の依存解決を含め、バージョンの固定・ロールバックは提供しません。

旧構成の `cleanup = "zap"` に相当する「宣言にないパッケージの削除」は自動では行いません。`mise -C mac bootstrap packages prune --dry-run` で対象を確認してから `mise -C mac bootstrap packages prune` を実行します。formula は Homebrew で手動導入したものも対象になるため、必ず dry-run を先に見ます。

Dock と Finder の defaults は書き込み後に `killall Dock Finder` で反映されます。mise は自動で再起動しません。状態は `mise -C mac bootstrap macos defaults status` で確認できます。

初回は eza テーマのリポジトリが存在せず、全体の dry-run がリンク元不足で停止することがあります。取得予定だけを確認する場合は `mise -C mac bootstrap --only packages,repos --dry-run` を使います。

## 検証

`.github/workflows/mac-setup.yml` は macOS 15 (Apple Silicon) のランナーで、シェルの構文チェック、設定ファイルの読み込み、defaults とファイルの状態確認、ツールの導入 dry-run、dotfiles の dry-run を実行します。master への push と PR のときだけ動き、対象は mac、dotfiles、scripts、setup.sh とワークフロー自身の変更に限定しています。Homebrew パッケージの導入と macOS の設定変更は行いません。
