# Linux セットアップ

Ubuntu 26 と、その WSL 環境を対象に、mise と apt で環境を構築します。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、このディレクトリ (`ubuntu/`) で一般ユーザーとして実行します。AI エージェントのワーカーには `../ubuntu-worker/` を使います。

```bash
./run.sh prepare
./run.sh bootstrap
exec bash -l
```

`prepare` は curl か git が無ければ apt で取得用の最小限の依存を入れ、独立した mise を `~/.local/bin/mise` に導入します。導入済みなら何もしないため、実行は初回だけで済みます。mise 本体の更新は `update` と共通設定の `self_update.auto` が担います。必要バージョンは 2026.10.14 以上で、`mise.toml` の `min_version` が検査します。

`bootstrap` は Ubuntu 26 であることを確認し、WSL の場合は追加設定を選択します。apt パッケージ、外部リポジトリ、dotfiles、ツール、krew プラグインの順に適用します。apt の操作には sudo が必要です。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

この環境は `../ubuntu-worker/` の最小構成に、人が使うマシン向けの追加分を重ねたものです。`prepare`、`bootstrap`、`update` の本体は `scripts/` にあり、`../ubuntu-worker/` の `run.sh` からも呼びます。

- `run.sh`: 入口。このディレクトリの設定を対象に `scripts/` のスクリプトを実行します。
- `mise.toml`: 必要バージョンと、最小構成の apt パッケージ、共通ツール設定の読み込み。`mise/conf.d/*.toml` は同じディレクトリの設定として自動で読み込まれ、このファイルの trust に含まれます。
- `../ubuntu-worker/mise/conf.d/packages.toml`: 最小構成の apt パッケージ。`mise.toml` が include します。
- `mise/conf.d/packages.toml`: 追加で取得するもの。外部リポジトリと追加の apt パッケージ。sudo が必要なのは apt パッケージだけです。
- `mise/conf.d/dotfiles.toml`: ホームに配置するシンボリックリンク。リンク元の相対パスはこのファイルの位置が基準です。mise は `[dotfiles]` を include できないため、最小構成のリンクは `../ubuntu-worker/mise/conf.d/dotfiles.toml` と両方に書いています。最小構成のリンクの欠けは CI が検出します。
- `mise/conf.d/tasks.toml`: 追加処理のタスク。
- `mise/conf.d/wsl/mise.wsl.toml`: WSL の認証情報へのリンクと Windows ホームの指定。`-E wsl` のときだけ読み込まれます。フォルダは独立した config root のため `scripts/environment.sh` が個別に trust します。
- `../dotfiles/.config/mise/config.toml`: 全 OS 共通のランタイムと CLI ツールの最小構成。
- `../dotfiles/.config/mise/conf.d/linux.toml`: Linux 固有の CLI ツールの最小構成。ホームにも配置され、どのディレクトリでも利用できます。
- `../dotfiles/.config/mise/conf.d/workstation.toml`: 人が使うマシン向けの全 OS 共通 CLI ツール。
- `../dotfiles/.config/mise/conf.d/linux-workstation.toml`: 人が使う Linux マシン向けの CLI ツール。
- `../dotfiles/.config/mise/conf.d/wsl.toml`: WSL のみで使う SSH エージェント。
- `../dotfiles/.config/mise/conf.d/settings.toml`: mise 本体の設定 (`self_update.auto`)。ホームにだけ配置し、`mise.toml` からは include しません。

ホームに配置するファイルの実体は、OS を問わずリポジトリ直下の `dotfiles/` にホームと同じ構造で置きます。どの環境が何を使うかは各環境の `mise/conf.d/dotfiles.toml` が決めます。

- `mise/conf.d/tasks.toml` の `krew:install` タスク: 未導入の krew プラグインを導入。`bootstrap` タスクから呼び出し、単独では `mise -C ubuntu run krew:install` で実行できます。

Git・curl などの基盤と共有ライブラリは apt、開発 CLI は mise が担当します。fastfetch は通常の配布バイナリを使います。

## 更新と確認

```bash
./run.sh bootstrap --dry-run
./run.sh update
./run.sh link
```

通常の適用は不足しているパッケージを導入します。`update` は mise 本体、宣言した apt パッケージ、mise ツールを更新して適用します。`link` は dotfiles の配置だけを行い、`bootstrap --link-only` と同じです。`--dry-run` は `bootstrap` と `link` で使えます。

初回は外部リポジトリが存在せず、全体の dry-run がテーマ等のリンク元不足で停止することがあります。取得予定だけを確認する場合は `mise -C ubuntu bootstrap --only packages,repos --dry-run` を使います。WSL では `mise -C ubuntu -E wsl bootstrap --only packages,repos --dry-run` を使います。

eza テーマと LazyVim starter は既定ブランチに追従し、`update` で fast-forward されます。checkout 内に未コミットの変更があると更新は止まります。ツールの `latest` と apt の依存解決を含め、バージョンの固定・ロールバックは提供しません。

WSL の Windows ホームは `/mnt/c/Users/tetsuzin` に固定しています。mise の `[dotfiles]` はリンク元でテンプレートや環境変数を展開しないためです。ユーザー名が異なる場合やリンクを除外する場合は、git 管理外の `ubuntu/mise/conf.d/wsl/mise.wsl.local.toml` に同じリンク先のエントリを書いて上書きします。例: `"~/.aws/credentials" = "/mnt/c/Users/<name>/.aws/credentials"`、除外は `"~/.kube/config" = { enabled = false }`。`.aws/credentials` と `.kube/config` を `[dotfiles]` で共有し、リンク元が存在しない場合はスキップせずエラーになります。既存ファイルとの競合は mise が検出し、`--link-force=y` を指定しない限り置き換えません。

リンクは `link` や `--dry-run`、mise の dotfiles status の対象になります。krew タスクの dry-run はスクリプトを表示し、個々のプラグインの導入状態までは確認しません。

## 検証

`.github/workflows/linux-setup.yml` が Ubuntu 26.04 のランナーで次を確認します。手元で流すテストはありません。

- シェルの構文チェック
- `ubuntu` の `[dotfiles]` が `ubuntu-worker` のリンクをすべて含むこと
- `ubuntu` と `ubuntu-worker` の設定ファイルの読み込み、ツールの導入 dry-run
- `ubuntu` の `./run.sh link --dry-run`
- `ubuntu-worker` の `./run.sh link` の実適用と、人が使うマシン向けの設定が配置されないこと

master への push と PR のときだけ動き、対象は ubuntu、ubuntu-worker、dotfiles、scripts とワークフロー自身の変更に限定しています。作業ブランチへの push だけでは実行されません。apt パッケージの適用とツールのダウンロードは行いません。WSL の設定は対象外で、実機の `./run.sh bootstrap --dry-run` で確認します。
