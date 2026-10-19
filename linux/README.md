# Linux セットアップ

Ubuntu 26 の x86_64 と、その WSL 環境を対象に、mise と apt で環境を構築します。Linux では Nix・Home Manager・DotfilesLinker は不要です。macOS は従来の Nix 構成を使います。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、一般ユーザーで実行します。

```bash
./setup.sh prepare
./setup.sh switch
exec bash -l
```

`prepare` は apt で取得用の最小限の依存を入れ、独立した mise を `~/.local/bin/mise` に導入します。必要バージョンは 2026.10.14 以上です。

`switch` は Ubuntu 26 であることを確認し、WSL の場合は追加設定を選択します。apt パッケージ、外部リポジトリ、dotfiles、ツール、krew プラグインの順に適用します。apt の操作には sudo が必要です。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

- `mise.toml`: apt パッケージ、外部リポジトリ、dotfiles、追加処理。
- `mise.wsl.toml` / `wsl-tools.toml`: WSL のみで使う SSH エージェント。
- `dotfiles/HOME/.config/mise/conf.d/linux.toml`: Linux の CLI ツール。ホームにも配置され、どのディレクトリでも利用できます。
- `../common/dotfiles/HOME/.config/mise/config.toml`: 従来からの共通ランタイム・ツール。
- `scripts/bootstrap.sh`: krew プラグイン、WSL の認証情報へのリンク。

Git・curl などの基盤と共有ライブラリは apt、開発 CLI は mise が担当します。`nh` は Nix 専用のため導入しません。fastfetch は通常の配布バイナリを使います。

## 更新と確認

```bash
./setup.sh switch --dry-run
./setup.sh switch --update
./setup.sh switch --link-only
```

通常の適用は不足しているパッケージを導入します。`--update` は宣言した apt パッケージと mise ツールを更新します。`--update-only` は macOS の flake.lock 更新用で、Linux では使用しません。

初回は外部リポジトリが存在せず、全体の dry-run がテーマ等のリンク元不足で停止することがあります。取得予定だけを確認する場合は `mise -C linux bootstrap --only packages,repos --dry-run` を使います。WSL では `mise -C linux -E wsl bootstrap --only packages,repos --dry-run` を使います。

eza テーマと LazyVim starter は旧 flake.lock のコミットに固定しています。更新する場合は `mise.toml` の `ref` を変更します。ツールの `latest` と apt の依存解決は flake.lock と同じ固定・ロールバックを提供しません。

## 既存の Home Manager 環境から移行

1. `.bashrc`、`.bash_profile`、`.config/nvim`、`.config/eza/theme.yaml` などの既存設定を退避します。Nix store を指すリンクは、必要な内容もコピーして保存します。
2. `./setup.sh prepare` で Nix に依存しない mise を導入します。
3. `./setup.sh switch` を実行します。競合するファイルは自動で上書きしません。退避後に必要な場合のみ `--link-force=y` を指定します。
4. 新しいログインシェルで `command -v mise git node nvim`、`dotnet --list-sdks`、`krew list` を確認します。通常の開発作業と WSL の SSH 連携も確認します。
5. Nix が不要になったことを確認してから、導入方式に対応する公式手順で別途アンインストールします。セットアップは Nix の削除や既存プロファイルの解除を行いません。

旧 `.profile` や起動済みシェルに Nix の PATH 設定が残る場合があります。移行後に個別に確認してください。

WSL の Windows ホームは `/mnt/c/Users/$(id -un)` が既定です。ユーザー名が異なる場合は `DOTFILES_WINDOWS_HOME=/mnt/c/Users/<name> ./setup.sh switch` で指定します。ホスト側に存在する `.aws/credentials` と `.kube/config` を共有し、既存の独立した設定との競合時には停止します。

## 検証

```bash
python3 -B -m unittest discover -s tests -v
```

mise 2026.10.14 以上を PATH に置くか、`TEST_MISE_BIN` に実行ファイルを指定します。テストは一時ホームで配置・再適用・競合保護・Ubuntu の依存パッケージと WSL 設定を確認します。apt の適用やツールのダウンロードは行いません。
