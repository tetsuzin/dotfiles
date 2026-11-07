# Linux セットアップ

Ubuntu 26 と、その WSL 環境を対象に、mise と apt で環境を構築します。Nix・Home Manager・DotfilesLinker は不要です。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、一般ユーザーで実行します。

```bash
./setup.sh prepare
./setup.sh bootstrap
exec bash -l
```

`prepare` は apt で取得用の最小限の依存を入れ、独立した mise の最新版を `~/.local/bin/mise` に導入します。導入済みなら `mise self-update` で更新します。必要バージョンは 2026.10.14 以上で、`mise.toml` の `min_version` が検査します。

`bootstrap` は Ubuntu 26 であることを確認し、WSL の場合は追加設定を選択します。apt パッケージ、外部リポジトリ、dotfiles、ツール、krew プラグインの順に適用します。apt の操作には sudo が必要です。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

- `mise.toml`: 必要バージョンと共通ツール設定の読み込みだけ。`mise/conf.d/*.toml` は同じディレクトリの設定として自動で読み込まれ、このファイルの trust に含まれます。
- `mise/conf.d/packages.toml`: 外部から取得するもの。apt パッケージと外部リポジトリ。sudo が必要なのは apt パッケージだけです。
- `mise/conf.d/dotfiles.toml`: ホームに配置するシンボリックリンク。リンク元の相対パスはこのファイルの位置が基準です。
- `mise/conf.d/tasks.toml`: 追加処理のタスク。
- `mise/conf.d/wsl/mise.wsl.toml`: WSL の認証情報へのリンクと Windows ホームの指定。`-E wsl` のときだけ読み込まれます。フォルダは独立した config root のため bootstrap.sh が個別に trust します。
- `dotfiles/HOME/.config/mise/conf.d/wsl.toml`: WSL のみで使う SSH エージェント。
- `dotfiles/HOME/.config/mise/conf.d/linux.toml`: Linux の CLI ツール。ホームにも配置され、どのディレクトリでも利用できます。
- `../common/dotfiles/HOME/.config/mise/config.toml`: 従来からの共通ランタイム・ツール。
- `mise/conf.d/tasks.toml` の `krew:install` タスク: 未導入の krew プラグインを導入。`bootstrap` タスクから呼び出し、単独では `mise -C linux run krew:install` で実行できます。

Git・curl などの基盤と共有ライブラリは apt、開発 CLI は mise が担当します。`nh` は Nix 専用のため導入しません。fastfetch は通常の配布バイナリを使います。

## 更新と確認

```bash
./setup.sh bootstrap --dry-run
./setup.sh bootstrap --update
./setup.sh bootstrap --link-only
```

通常の適用は不足しているパッケージを導入します。`--update` は宣言した apt パッケージと mise ツールを更新します。

初回は外部リポジトリが存在せず、全体の dry-run がテーマ等のリンク元不足で停止することがあります。取得予定だけを確認する場合は `mise -C linux bootstrap --only packages,repos --dry-run` を使います。WSL では `mise -C linux -E wsl bootstrap --only packages,repos --dry-run` を使います。

eza テーマと LazyVim starter は既定ブランチに追従し、`--update` で fast-forward されます。checkout 内に未コミットの変更があると更新は止まります。ツールの `latest` と apt の依存解決を含め、Nix の flake.lock のような固定・ロールバックは提供しません。

## 既存の Home Manager 環境から移行

1. `.bashrc`、`.bash_profile`、`.config/nvim`、`.config/eza/theme.yaml` などの既存設定を退避します。Nix store を指すリンクは、必要な内容もコピーして保存します。
2. `./setup.sh prepare` で Nix に依存しない mise を導入します。
3. `./setup.sh bootstrap` を実行します。競合するファイルは自動で上書きしません。退避後に必要な場合のみ `--link-force=y` を指定します。
4. 新しいログインシェルで `command -v mise git node nvim`、`dotnet --list-sdks`、`krew list` を確認します。通常の開発作業と WSL の SSH 連携も確認します。
5. Nix が不要になったことを確認してから、導入方式に対応する公式手順で別途アンインストールします。セットアップは Nix の削除や既存プロファイルの解除を行いません。アンインストール後は `mise reshim` を実行します。shims は Nix 版 mise へのリンクとして作られているため、そのままではログインシェルからツールが見えなくなります。

WSL の `~/.aws/credentials` と `~/.kube/config` が旧 Home Manager のリンクの場合は、リンク先と必要な内容を確認・退避してからリンクを外し、bootstrap で直接リンクを作成します。この移行処理は自動では行いません。

旧 `.profile` や起動済みシェルに Nix の PATH 設定が残る場合があります。移行後に個別に確認してください。

WSL の Windows ホームは `/mnt/c/Users/tetsuzin` に固定しています。mise の `[dotfiles]` はリンク元でテンプレートや環境変数を展開しないためです。ユーザー名が異なる場合やリンクを除外する場合は、git 管理外の `linux/mise/conf.d/wsl/mise.wsl.local.toml` に同じリンク先のエントリを書いて上書きします。例: `"~/.aws/credentials" = "/mnt/c/Users/<name>/.aws/credentials"`、除外は `"~/.kube/config" = { enabled = false }`。`.aws/credentials` と `.kube/config` を `[dotfiles]` で共有し、リンク元が存在しない場合はスキップせずエラーになります。既存ファイルとの競合は mise が検出し、`--link-force=y` を指定しない限り置き換えません。

リンクは `--link-only` や `--dry-run`、mise の dotfiles status の対象になります。krew タスクの dry-run はスクリプトを表示し、個々のプラグインの導入状態までは確認しません。

## 検証

```bash
dotnet run tests/LinuxSetup.cs
dotnet run tests/LinuxSetup.cs -- -method '*Wsl*'   # 名前で絞り込み
```

.NET 10 SDK のファイルベースアプリとして実行します。初回は xUnit の NuGet 復元が必要です。mise 2026.10.14 以上を PATH に置くか、`TEST_MISE_BIN` に実行ファイルを指定します。テストは一時ホームで配置・再適用・競合保護・Ubuntu の依存パッケージと WSL 設定を確認します。apt の適用やツールのダウンロードは行いません。

`tests/LinuxSetup.cs` は、設定ファイルとスクリプトの論理が壊れていないかを確認する回帰テストです。一時ディレクトリを HOME にし、`MISE_OFFLINE=true` でネットワークを遮断した上で `mise -C linux` を直接呼び出します。eza テーマと LazyVim starter はダミーで代用し、krew や grep などの外部コマンドは PATH 先頭に置いたスタブで差し替えます。本番に近い環境で bootstrap を通す確認ではありません。

テストは .NET 10 のファイルベースアプリとして 1 ファイルの C# で書き、`#:package` 指示子で xUnit v3 を使っています。dotnet は mise の共通ツールに含まれるため追加導入はなく、一時ホームの隔離と後始末、子プロセスの実行、JSON の読み取りは標準ライブラリで揃います。xUnit はテストごとにクラスのインスタンスを作って `Dispose` を呼ぶので、一時ホームの後始末もそれに任せています。

`.github/workflows/linux-setup.yml` は Ubuntu 26.04 のランナーで、シェルの構文チェックと上記のテストを実行します。main への push と PR のときだけ動き、対象は linux、common/dotfiles、scripts、tests、setup.sh とワークフロー自身の変更に限定しています。作業ブランチへの push だけでは実行されません。
