# Windows セットアップ

Windows 11 を対象に、mise と winget、scoop で環境を構築します。コマンドの一覧と全体の構成は [../README.md](../README.md) にあります。

## 初回セットアップ

Git が無い状態では、PowerShell から scoop と Git を入れてリポジトリを clone します。Git は以降も scoop の宣言 (`mise/conf.d/packages.toml`) で管理します。

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install git
git clone https://github.com/tetsuzin/dotfiles.git
```

以降は `run.cmd` を入口にします。cmd、PowerShell、Windows Terminal のどこからでも実行できます。

```powershell
cd dotfiles\windows
.\run.cmd prepare
.\run.cmd bootstrap
```

`prepare` は scoop 本体と extras バケット、mise 本体を入れ、ユーザーの Path に `~\.local\bin` を追加します。実行後は新しいターミナルを開きます。

`bootstrap` に管理者権限は不要ですが、インストーラが UAC プロンプトを出すことがあります。dotfiles はシンボリックリンクで配置するため、開発者モード (設定 > システム > 開発者向け) を有効にしておきます。

## 役割分担

PowerShell・Windows Terminal などシステム寄りの基盤は winget、Git や圧縮ツールなどユーザー領域の基盤は scoop、開発 CLI は mise が担当します。

## 注意点

- **Git の設定**: `~/.config/git/config` に配置します。`~/.gitconfig` が既にある場合は両方が読まれ、重複する項目は `~/.gitconfig` が優先されます。マシン固有の設定 (ghq の root や safe.directory など) は `~/.gitconfig` に残せます。
- **scoop のバージョン固定**: 固定した項目は `update` でも更新されません。
- **変更内容の確認**: `--dry-run` のほか、`mise -C windows bootstrap status` と `mise -C windows dotfiles diff` で事前に確認できます。
- **Claude Code と Git Bash**: `bootstrap` はユーザー環境変数 `CLAUDE_CODE_GIT_BASH_PATH` に scoop の Git Bash を設定します。反映には VS Code や Claude Code の再起動が必要です。

## 既存の環境から移行

1. `mise -C windows bootstrap status` で、winget / scoop パッケージと dotfiles の現状を確認します。scoop で入れたものは winget からは見えず、その逆も同じなので、宣言したマネージャと実際の導入元が違うものは二重に導入されます。先に整理するか、`packages.toml` の該当行を直します。
2. `.\run.cmd prepare` を実行します。scoop や winget で入れた mise が残っていると警告が出るので、`scoop uninstall mise` や `winget uninstall jdx.mise` で外し、1 つの導入方法に揃えます。導入済みのツールのデータ (`~\AppData\Local\mise`) は残るため再ダウンロードは不要です。
3. `.\run.cmd bootstrap --dry-run` で変更予定を確認し、`.\run.cmd bootstrap` を実行します。既存ファイルは自動で上書きしません。退避後に必要な場合のみ `--force-dotfiles` を指定します。
4. 新しい PowerShell で `Get-Command mise`、`mise doctor`、`mise ls` を確認します。shims が古い mise を指している場合は `mise reshim` を実行します。
5. mise の `[tools]` に移したツール (act、jq、shfmt、starship など) は scoop 側を `scoop uninstall` で外します。残したままでも動きますが、PATH の順序で古い方が実行されることがあります。

## mise のアンインストール

セットアップは mise の削除を行いません。`mise implode --dry-run` で削除対象を確認してから `mise implode` を実行すると、本体 (`~\.local\bin\mise.exe`)、導入したツール、状態、キャッシュが消えます。`~\.config\mise` はリポジトリへのリンクなので残します。PowerShell プロファイルの `mise activate` の行と、ユーザーの Path に追加された `~\.local\bin` は手で外します。
