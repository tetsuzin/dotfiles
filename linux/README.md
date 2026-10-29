# Linux セットアップ

Ubuntu 26 と、その WSL 環境を対象に、mise と apt で環境を構築します。Linux では Nix・Home Manager・DotfilesLinker は不要です。macOS は従来の Nix 構成を使います。

## 初回セットアップ

リポジトリを継続して置く場所へ clone し、一般ユーザーで実行します。

```bash
./setup.sh prepare
./setup.sh bootstrap
exec bash -l
```

`prepare` は apt で取得用の最小限の依存を入れ、独立した mise を `~/.local/bin/mise` に導入します。必要バージョンは 2026.10.14 以上です。

`bootstrap` は Ubuntu 26 であることを確認し、WSL の場合は追加設定を選択します。apt パッケージ、外部リポジトリ、dotfiles、ツール、krew プラグインの順に適用します。apt の操作には sudo が必要です。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

- `mise.toml`: apt パッケージ、外部リポジトリ、dotfiles、追加処理。
- `mise.wsl.toml`: WSL の認証情報へのリンクと Windows ホームの指定。
- `dotfiles/HOME/.config/mise/conf.d/wsl.toml`: WSL のみで使う SSH エージェント。
- `dotfiles/HOME/.config/mise/conf.d/linux.toml`: Linux の CLI ツール。ホームにも配置され、どのディレクトリでも利用できます。
- `../common/dotfiles/HOME/.config/mise/config.toml`: 従来からの共通ランタイム・ツール。
- `mise.toml` の `krew:install` タスク: 未導入の krew プラグインを導入。`bootstrap` タスクから呼び出し、単独では `mise -C linux run krew:install` で実行できます。

Git・curl などの基盤と共有ライブラリは apt、開発 CLI は mise が担当します。`nh` は Nix 専用のため導入しません。fastfetch は通常の配布バイナリを使います。

## 更新と確認

```bash
./setup.sh bootstrap --dry-run
./setup.sh bootstrap --update
./setup.sh bootstrap --link-only
```

通常の適用は不足しているパッケージを導入します。`--update` は宣言した apt パッケージと mise ツールを更新します。`--update-only` は macOS の flake.lock 更新用で、Linux では使用しません。

初回は外部リポジトリが存在せず、全体の dry-run がテーマ等のリンク元不足で停止することがあります。取得予定だけを確認する場合は `mise -C linux bootstrap --only packages,repos --dry-run` を使います。WSL では `mise -C linux -E wsl bootstrap --only packages,repos --dry-run` を使います。

eza テーマと LazyVim starter は旧 flake.lock のコミットに固定しています。更新する場合は `mise.toml` の `ref` を変更します。ツールの `latest` と apt の依存解決は flake.lock と同じ固定・ロールバックを提供しません。

## 既存の Home Manager 環境から移行

1. `.bashrc`、`.bash_profile`、`.config/nvim`、`.config/eza/theme.yaml` などの既存設定を退避します。Nix store を指すリンクは、必要な内容もコピーして保存します。
2. `./setup.sh prepare` で Nix に依存しない mise を導入します。
3. `./setup.sh bootstrap` を実行します。競合するファイルは自動で上書きしません。退避後に必要な場合のみ `--link-force=y` を指定します。
4. 新しいログインシェルで `command -v mise git node nvim`、`dotnet --list-sdks`、`krew list` を確認します。通常の開発作業と WSL の SSH 連携も確認します。
5. Nix が不要になったことを確認してから、導入方式に対応する公式手順で別途アンインストールします。セットアップは Nix の削除や既存プロファイルの解除を行いません。

WSL の `~/.aws/credentials` と `~/.kube/config` が旧 Home Manager のリンクの場合は、リンク先と必要な内容を確認・退避してからリンクを外し、bootstrap で直接リンクを作成します。この移行処理は自動では行いません。

旧 `.profile` や起動済みシェルに Nix の PATH 設定が残る場合があります。移行後に個別に確認してください。

WSL の Windows ホームは `/mnt/c/Users/$USER` が既定です。ユーザー名が異なる場合は `DOTFILES_WINDOWS_HOME=/mnt/c/Users/<name> ./setup.sh bootstrap` で指定します。`.aws/credentials` と `.kube/config` を mise の `[dotfiles]` で共有します。リンク元が存在しない場合はスキップせずエラーになります。Windows 側に存在しないファイルへのリンクを除外するには、`linux/mise.wsl.local.toml` に同じリンク先のエントリを `enabled = false` 付きで書きます。例: `"~/.kube/config" = { source = "{{ vars.windows_home }}/.kube/config", enabled = false }`。既存ファイルとの競合は mise が検出し、`--link-force=y` を指定しない限り置き換えません。

リンクは `--link-only` や `--dry-run`、mise の dotfiles status の対象になります。krew タスクの dry-run はスクリプトを表示し、個々のプラグインの導入状態までは確認しません。

## 検証

```bash
python3 -B -m unittest discover -s tests -v
```

mise 2026.10.14 以上を PATH に置くか、`TEST_MISE_BIN` に実行ファイルを指定します。テストは一時ホームで配置・再適用・競合保護・Ubuntu の依存パッケージと WSL 設定を確認します。apt の適用やツールのダウンロードは行いません。

`tests/test_linux_setup.py` は、設定ファイルとスクリプトの論理が壊れていないかを確認する回帰テストです。一時ディレクトリを HOME にし、`MISE_OFFLINE=true` でネットワークを遮断した上で `mise -C linux` を直接呼び出します。eza テーマと LazyVim starter はダミーで代用し、krew や grep などの外部コマンドは PATH 先頭に置いたスタブで差し替えます。本番に近い環境で bootstrap を通す確認ではありません。

テストは Python 標準の unittest で書いています。CI と手元の Ubuntu に追加導入なしで動き、一時ホームの隔離と後始末、失敗時の stdout と stderr の表示、JSON の読み取りが標準で揃うためです。bash でも書けますが、同じ長さでこれらの利点を失うだけなので採用していません。

`.github/workflows/linux-setup.yml` は Ubuntu 26.04 のランナーで、シェルの構文チェックと上記のテストを実行します。main への push と PR のときだけ動き、対象は linux、common/dotfiles、scripts、tests、setup.sh とワークフロー自身の変更に限定しています。作業ブランチへの push だけでは実行されません。
