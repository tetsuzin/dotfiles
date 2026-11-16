# AI エージェントのワーカー用 Linux セットアップ

Ubuntu 26 を対象に、AI エージェントを動かすための最小構成を mise と apt で構築します。人が使うマシンには `../ubuntu/` を使います。

## セットアップ

リポジトリを継続して置く場所へ clone し、このディレクトリ (`ubuntu-worker/`) で一般ユーザーとして実行します。

```bash
./run.sh prepare
./run.sh bootstrap
exec bash -l
```

`--dry-run`、`--update`、`--link-only`、`--link-force=y` の意味は `../ubuntu/README.md` と同じです。処理の本体は `../scripts/ubuntu/` にあり、`../ubuntu/` と共通です。

## 入るもの

- mise ツール: claude、codex、dotnet、node、python、gh、fd、jq
- apt パッケージ: ビルド、dotnet の依存ライブラリ、git、ripgrep、SSH 接続の受け付けに必要なもの
- dotfiles: mise、git、bash、Claude Code、Codex の設定

k8s、AWS、Docker、エディタ、プロンプトや TUI などの対話用ツールと、外部リポジトリの取得、krew タスクは含みません。

## 設定の管理先

- `run.sh`: 入口。このディレクトリの設定を対象に `../scripts/ubuntu/` のスクリプトを実行します。
- `mise.toml`: 必要バージョンと最小構成のツール設定の読み込み。
- `mise/conf.d/packages.toml`: apt パッケージ。`../ubuntu/mise.toml` からも include されます。
- `mise/conf.d/dotfiles.toml`: ホームに配置するシンボリックリンク。mise は `[dotfiles]` を include できないため、変えるときは `../ubuntu/mise/conf.d/dotfiles.toml` も揃えます。食い違いはテストが検出します。
- `../dotfiles/.config/mise/config.toml`: 全 OS 共通のランタイムと CLI ツールの最小構成。
- `../dotfiles/.config/mise/conf.d/linux.toml`: Linux 固有の CLI ツールの最小構成。

ワーカーにツールを足すときは、上の 2 つの最小構成に書きます。`../ubuntu/` にも同じものが入ります。

## 検証

`dotnet run tests/LinuxSetup.cs` が `ubuntu` と合わせてこの環境も確認します。詳細は `../ubuntu/README.md` を参照してください。
