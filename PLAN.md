# Linux / WSL の mise 移行計画

ブランチ: `feat/linux-mise-bootstrap`
作成日: 2026-10-26

## 目的

Linux (Ubuntu 26) と WSL の環境構築を Nix + Home Manager + DotfilesLinker から mise + apt に移行する。
macOS は従来どおり Nix (flake + nix-darwin + Home Manager) を使う。

## 現在の構成

| 役割 | ファイル |
|---|---|
| 入口 | `setup.sh` (`prepare` / `bootstrap` / `switch`、OS 自動判定) |
| ホスト準備 | `linux/scripts/prepare.sh`: apt 最小依存 + `~/.local/bin/mise` を導入 |
| 本体 | `linux/scripts/bootstrap.sh`: `mise trust` → `mise bootstrap` (WSL は `-E wsl`) |
| 環境判定 | `linux/scripts/environment.sh`: Ubuntu 26 / 非 root / WSL 判定 |
| 宣言 | `linux/packages.toml`: `[bootstrap.packages]` (apt、sudo が必要)。`linux/mise.toml`: `[bootstrap.repos]` (eza-themes / LazyVim starter を旧 flake.lock のコミットに固定)、`[dotfiles]`、`krew:install` タスク |
| WSL 差分 | `linux/mise.wsl.toml`: Windows ホームの `.aws/credentials` と `.kube/config` をリンク。`linux/wsl-tools.toml`: wsl2-ssh-agent |
| ツール | `linux/dotfiles/HOME/.config/mise/conf.d/linux.toml` (Linux CLI)、`common/dotfiles/HOME/.config/mise/config.toml` (ランタイム) |
| 検証 | `tests/test_linux_setup.py`、CI `.github/workflows/linux-setup.yml` (ubuntu-26.04) |

必要バージョン: mise 2026.10.14 以上 (`linux/mise.toml` の `min_version` で管理)。

## 既知の問題

1. **テストが壊れている**
   `tests/test_linux_setup.py` の `test_krew_and_wsl_links_are_idempotent` が `linux/scripts/post-bootstrap.sh` を呼んでいるが、このスクリプトはコミット 6e1899b で削除済み。CI で確実に失敗する。
   krew 処理は `mise.toml` の `krew:install` タスクに、WSL リンクは `mise.wsl.toml` の `[dotfiles]` に移っている。
2. **ローカルで検証できていない**
   この WSL の mise は Nix profile の 2026.9.18 で、`~/.local/bin/mise` は未導入。`mise bootstrap` サブコマンドや `[bootstrap.*]` セクションなど 2026.10 系の挙動は未確認。
3. **無関係な差分が混在**
   `common/dotfiles/HOME/.claude/settings.json` に `model: fable` と `modelSettings` を追加した未コミット差分がある。移行とは無関係。
4. **origin/main と共通祖先がない**
   `git merge-base HEAD origin/main` が空。`backup/monorepo-before-rebase-20260926` があるため履歴を書き換えた結果と思われる。PR の base をどうするか決める必要がある。
5. **(修正済み 2026-10-30)** `mise.wsl.toml` の `{{ vars.windows_home }}` が展開されない (mise 2026.10.14 で確認)
   `[dotfiles]` のリンク元がテンプレート文字列のまま `linux/{{ vars.windows_home }}/.aws/credentials` と解釈され、`sources do not exist` で `-E wsl` の `dotfiles apply` と `bootstrap` が失敗する。WSL ホストでは `./setup.sh bootstrap --link-only` も同じ理由で失敗する。
   `test_wsl_tools_are_deployed_only_for_wsl` と `test_setup_entrypoint_without_nix` (WSL 上で実行時) がこれで落ちる。`[dotfiles]` のリンク元はテンプレートも環境変数も展開しないため、`/mnt/c/Users/tetsuzin` に固定し、差分は git 管理外の `mise.wsl.local.toml` で上書きする方式にした。
6. **README の未検証記述**
   `linux/README.md` の `mise -C linux bootstrap --only packages,repos --dry-run` など、`--only` の指定値や dry-run の挙動は実機で未確認。

## 作業手順

- [x] `[bootstrap.packages]` を `linux/packages.toml` に分離する (2026-10-30)。include 先でもマージされ、`mise trust mise.toml` でディレクトリごと trust されるため追加の trust は不要
- [ ] `settings.json` の差分を別コミットに分離する
- [x] `mise.wsl.toml` の Windows ホーム指定を固定パスにし、`mise.wsl.local.toml` で上書きできるようにする
- [ ] 壊れたテストを書き直す
  - krew: `krew` スタブを PATH に置き `mise run krew:install` を 2 回実行して冪等性を確認
  - WSL リンク: `test_wsl_tools_are_deployed_only_for_wsl` が一時的な `mise.wsl.local.toml` でリンク先を確認済み。競合時の保護の確認を追加する
- [ ] この WSL で `./setup.sh prepare` を実行し mise 2026.10 系を `~/.local/bin/mise` に導入する
- [ ] `./setup.sh bootstrap --dry-run` と `--only packages,repos --dry-run` で計画を確認し、README の記述を実態に合わせる
- [ ] `python3 -B -m unittest discover -s tests -v` をローカルで通す
- [ ] 既存設定を退避してから `./setup.sh bootstrap` を本適用する (README の「既存の Home Manager 環境から移行」に従う)
- [ ] 新しいログインシェルで `command -v mise git node nvim`、`dotnet --list-sdks`、`krew list`、WSL の SSH 連携を確認する
- [ ] Nix が不要になったことを確認してから、公式手順で Nix をアンインストールする
- [ ] PR の base ブランチを決めて PR を作成する

## 注意

- `mise bootstrap` 系のコマンドは status 確認でも実ホームの古いツールバージョンを削除する。検証はテストと同じく一時ホーム (`HOME` と `XDG_*` を差し替え) で行うこと

## 移行後に残る差分

- ツールの `latest` と apt の依存解決は flake.lock のような固定・ロールバックを提供しない
- `nh` は Nix 専用のため導入しない。fastfetch は配布バイナリを使う
- 旧 `.profile` や起動済みシェルに Nix の PATH 設定が残る場合は個別に対処する
