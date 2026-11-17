# dotfiles

Ubuntu (WSL を含む)、macOS、Windows の環境を mise で構築します。OS パッケージ、dotfiles の配置、開発ツールの導入を `mise bootstrap` に任せ、このリポジトリは宣言と薄い入口だけを持ちます。

## 使い方

適用したい OS のディレクトリで実行します。OS ごとの準備と注意点は各ディレクトリの README にあります。

- [ubuntu/](ubuntu/README.md): Ubuntu 26 と WSL。人が使うマシンと AI エージェントのワーカーを `--env` で選びます。
- [mac/](mac/README.md): Apple Silicon の macOS。
- [windows/](windows/README.md): Windows 11。`run.sh` の代わりに `run.cmd` を使います。

```bash
./run.sh prepare     # 初回だけ。mise 本体と、その導入に必要なものを入れる
./run.sh bootstrap   # 環境の適用と dotfiles の配置
./run.sh update      # mise 本体、宣言した OS パッケージ、mise ツールを更新して適用
./run.sh link        # dotfiles の配置だけ
```

`bootstrap`、`update`、`link` の後ろに付けた引数は `mise bootstrap` にそのまま渡します。

- `--dry-run`: 変更予定を表示します。
- `--force-dotfiles`: 既存ファイルと競合する dotfiles の置き換えを許可します。指定しない限り、既存ファイルは上書きしません。

## 構成

```
dotfiles/   ホームに配置するファイルの実体。ホームと同じ構造で置く
scripts/    ubuntu と mac の run.sh が読み込む共通の流れ
ubuntu/     ┐
mac/        ├ OS ごとの入口 (run.sh / run.cmd) と mise の設定
windows/    ┘
```

各 OS のディレクトリには、入口のほかに `mise.toml` と `mise/conf.d/` があります。何を入れてどこにリンクするかはここに宣言します。各ファイルの役割は、そのファイルの冒頭のコメントに書いています。

## mise のツール設定

`dotfiles/.config/mise/` はホームの `~/.config/mise/` にリンクされ、どのディレクトリでも使うツールを決めます。

- `config.toml`: 全マシン共通の最小構成です。AI エージェントのワーカーにはこれだけを配置します。
- それ以外: 人が使うマシンにだけ配置します。`conf.d/workstation.toml` が全 OS 共通、`config.<os>.toml` が OS 固有の追加分です。

OS 固有のファイルは、`miserc.toml` の `auto_env` により、その OS でだけ読み込まれます。

## 方針

- mise 本体はパッケージマネージャではなく公式スクリプトで `~/.local/bin` に入れます。更新は `update` と、設定の `self_update.auto` が担います。
- ツールは `latest` に追従します。バージョンの固定とロールバックは提供しません。
- 宣言から外したパッケージの削除は自動では行いません。
- 検証は GitHub Actions の dry-run が中心です。master への push と PR で、OS ごとに設定の読み込みと dotfiles の dry-run を確かめます。対応する mise の最低バージョンは各 OS の `mise.toml` の `min_version` に書き、CI はそのバージョンで動かします。
