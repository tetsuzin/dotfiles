# Ubuntu セットアップ

Ubuntu 26 と、その WSL 環境を対象に、mise と apt で環境を構築します。コマンドの一覧と全体の構成は [../README.md](../README.md) にあります。

構成は 2 つあり、初回に `--env` で選びます。

- `workstation`: 人が使うマシン。最小構成に追加分を重ねます。WSL では WSL 用の設定も重ねます。
- `worker`: AI エージェントを動かすワーカー。最小構成だけを入れます。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、このディレクトリ (`ubuntu/`) で一般ユーザーとして実行します。

```bash
./run.sh prepare
./run.sh bootstrap --env workstation   # 人が使うマシン
./run.sh bootstrap --env worker        # AI エージェントのワーカー
exec bash -l
```

`--env` の指定は `~/.config/mise/miserc.local.toml` に記録され、2 回目からは省略できます。記録が無いマシンで省略するとエラーで止まります。構成を変えるときは `--env` を付けて実行し直します。

`bootstrap` の apt の操作には sudo が必要です。

## 構成の重ね方

最小構成を土台にし、追加分は mise のプロファイルとして重ねます。

- 最小構成: `mise.toml` と `mise/conf.d/` 直下のファイル
- `workstation` の追加分: `mise/conf.d/workstation/`
- WSL の追加分: `mise/conf.d/wsl/`

どのプロファイルを使うかは `miserc.local.toml` の `env` に記録されるので、`run.sh` でも素の `mise` コマンドでも同じ設定が読み込まれます。`worker` はプロファイルなしです。

## worker に入るもの

- mise ツール: claude、codex、dotnet、go、node、python、biome、shfmt、gh、fd、jq
- apt パッケージ: ビルド、dotnet の依存ライブラリ、git、ripgrep、SSH 接続の受け付けに必要なもの
- dotfiles: mise、git、bash、Claude Code、Codex の設定

k8s、AWS、Docker、エディタ、プロンプトや TUI などの対話用ツールと、外部リポジトリの取得、krew タスク、WSL 用の設定は含みません。ワーカーにツールを足すときは `../dotfiles/.config/mise/config.toml` に書きます。`workstation` にも同じものが入ります。

## 役割分担

Git・curl などの基盤と共有ライブラリは apt、開発 CLI は mise が担当します。

## 注意点

- **初回の dry-run**: 外部リポジトリがまだ無いため、全体の `--dry-run` がテーマ等のリンク元不足で止まることがあります。取得予定だけを見るには `mise -C ubuntu bootstrap --only packages,repos --dry-run` を使います。
- **外部リポジトリ**: eza テーマと LazyVim starter は既定ブランチに追従し、`update` で fast-forward されます。checkout 内に未コミットの変更があると更新は止まります。
- **WSL の Windows ホーム**: `/mnt/c/Users/tetsuzin` に固定しています。mise の `[dotfiles]` がリンク元でテンプレートや環境変数を展開しないためです。ユーザー名が異なる場合やリンクを外す場合は、git 管理外の `mise/conf.d/wsl/mise.wsl.local.toml` に同じリンク先のエントリを書いて上書きします。
  - 例: `"~/.aws/credentials" = "/mnt/c/Users/<name>/.aws/credentials"`
  - 除外: `"~/.kube/config" = { enabled = false }`
- **WSL で共有するファイル**: `.aws/credentials` と `.kube/config` を Windows 側と共有します。リンク元が存在しない場合はスキップせずエラーになります。
- **krew プラグイン**: `workstation` の `bootstrap` の最後に導入します。単独では `mise -C ubuntu run krew:install` で実行できます。
