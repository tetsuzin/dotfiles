# Windows セットアップ

Windows 11 を対象に、mise と winget、scoop で環境を構築します。Linux と同じ mise bootstrap の仕組みを使います。

## 初回セットアップ

Git が無い状態では、PowerShell から scoop と Git を入れてリポジトリを clone します。Git は以降も scoop の宣言 (`packages.toml`) で管理します。

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
scoop install git
git clone https://github.com/tetsuzin/dotfiles.git
```

以降は `setup.cmd` を入口にします。cmd、PowerShell、Windows Terminal のどこからでも実行できます。

```powershell
cd dotfiles
.\setup.cmd prepare
.\setup.cmd bootstrap
```

`setup.cmd` は `prepare` を PowerShell で実行し、それ以外のコマンドを Git Bash の `setup.sh` に転送します。Git Bash は `git --exec-path` から特定するため、WSL の bash が選ばれることはありません。Git Bash から直接 `./setup.sh prepare` や `./setup.sh bootstrap` を実行しても同じです。

`prepare` は scoop 本体と extras バケットが無ければ導入し、Linux と同じく公式スクリプトで独立した mise を `~\.local\bin` に導入します。導入済みなら何もしないため、実行は初回だけで済みます。mise 本体の更新は `bootstrap --update` と共通設定の `self_update.auto` が担います。スクリプトはユーザーの Path に `~\.local\bin` を追加します。必要バージョンは 2026.10.12 以上で、`mise.toml` の `min_version` が検査します。

`bootstrap` は winget / scoop パッケージ、dotfiles、ツール、`bootstrap` タスクの順に適用します。管理者権限は不要ですが、インストーラが UAC プロンプトを出すことがあります。dotfiles はシンボリックリンクで配置するため、開発者モード (設定 > システム > 開発者向け) を有効にしておきます。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

- `mise.toml`: 必要バージョンと共通ツール設定の読み込みだけ。`mise/conf.d/*.toml` は同じディレクトリの設定として自動で読み込まれ、このファイルの trust に含まれます。
- `mise/conf.d/packages.toml`: OS パッケージ。winget は PowerShell 7、Windows Terminal、GUI アプリ。scoop は Git、7-Zip、less、sudo、zellij などユーザー領域の CLI と GUI ツール。extras バケットのものは `scoop:extras/<name>` と書きますが、scoop は名前だけで照合するためバケットは prepare.ps1 が追加します。
- `mise/conf.d/dotfiles.toml`: ホームに配置するシンボリックリンク。`~` は `C:\Users\<name>` に解決され、リンク元の相対パスはこのファイルの位置が基準です。
- `mise/conf.d/tasks.toml`: `claude:git-bash-path` タスク。Claude Code が scoop の Git Bash を使えるよう、ユーザー環境変数 `CLAUDE_CODE_GIT_BASH_PATH` を設定します。`bootstrap` タスクから呼び出し、単独では `mise -C windows run claude:git-bash-path` で実行できます。反映には VS Code や Claude Code の再起動が必要です。
- `../dotfiles/.config/mise/conf.d/windows.toml`: Windows 固有の CLI ツール。ホームにも配置され、どのディレクトリでも利用できます。
- `../dotfiles/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`: PowerShell 7 のプロファイル。mise の activate と starship の初期化を含みます。
- `../dotfiles/.config/mise/config.toml`: 全 OS 共通のランタイムと CLI ツール。dotnet は Windows では Visual Studio 側に任せるため除外しています。
- `../dotfiles/.config/mise/conf.d/settings.toml`: mise 本体の設定 (`self_update.auto`)。ホームにだけ配置し、`mise.toml` からは include しません。

ホームに配置するファイルの実体は、OS を問わずリポジトリ直下の `dotfiles/` にホームと同じ構造で置きます。どの OS が何を使うかは各 OS の `mise/conf.d/dotfiles.toml` が決めます。

PowerShell・Windows Terminal などシステム寄りの基盤は winget、Git や圧縮ツールなどユーザー領域の基盤は scoop、開発 CLI は mise が担当します。Windows 向けビルドが無いツール (btop、krew、aws-cli など) は Linux の設定にだけ置きます。mise は `[bootstrap.mise_shell_activate]` で PowerShell に対応していないため、activate はプロファイルに直接書いています。

Git の設定は `~/.config/git/config` に配置します。`~/.gitconfig` が既にある場合は両方が読まれ、重複する項目は `~/.gitconfig` が優先されます。マシン固有の設定 (ghq の root や safe.directory など) はそのまま `~/.gitconfig` に残せます。

## 更新と確認

```powershell
.\setup.cmd bootstrap --dry-run
.\setup.cmd bootstrap --update
.\setup.cmd bootstrap --link-only
```

通常の適用は不足しているパッケージを導入します。`--update` は mise 本体、宣言した winget / scoop パッケージ、mise ツールを更新します。scoop でバージョンを固定した項目は更新されません。

mise は `~` を常に実際のユーザープロファイルに解決するため、Linux のテストのような一時ホームでの隔離は行えません。変更内容は `--dry-run` か、`mise -C windows bootstrap status` と `mise -C windows dotfiles diff` で事前に確認します。

## 既存の環境から移行

1. `mise -C windows bootstrap status` で、winget / scoop パッケージと dotfiles の現状を確認します。scoop で入れたものは winget からは見えず、その逆も同じなので、宣言したマネージャと実際の導入元が違うものは二重に導入されます。先に整理するか、`packages.toml` の該当行を直します。
2. `.\setup.cmd prepare` を実行します。scoop や winget で入れた mise が残っていると警告が出るので、`scoop uninstall mise` や `winget uninstall jdx.mise` で外し、1 つの導入方法に揃えます。導入済みのツールのデータ (`~\AppData\Local\mise`) は残るため再ダウンロードは不要です。
3. `.\setup.cmd bootstrap --dry-run` で変更予定を確認し、`.\setup.cmd bootstrap` を実行します。`~/.config/starship.toml`、`~/.claude/settings.json`、`~/.config/mise/config.toml`、PowerShell プロファイルなどの既存ファイルは自動で上書きしません。退避後に必要な場合のみ `--link-force=y` を指定します。
4. 新しい PowerShell で `Get-Command mise`、`mise doctor`、`mise ls` を確認します。shims が古い mise を指している場合は `mise reshim` を実行します。
5. mise の `[tools]` に移したツール (act、gh、jq、shfmt、starship など) は scoop 側を `scoop uninstall` で外します。残したままでも動きますが、PATH の順序で古い方が実行されることがあります。

## mise のアンインストール

セットアップは mise の削除を行いません。`mise implode --dry-run` で削除対象を確認してから `mise implode` を実行すると、本体 (`~\.local\bin\mise.exe`)、導入したツール、状態、キャッシュが消えます。`~\.config\mise` はリポジトリへのリンクなので残します。PowerShell プロファイルの `mise activate` の行と、ユーザーの Path に追加された `~\.local\bin` は手で外します。

## 検証

`.github/workflows/windows-setup.yml` は Windows ランナーで、シェルの構文チェック、設定ファイルの読み込み、ツールの導入 dry-run、dotfiles の dry-run を実行します。main への push と PR のときだけ動き、対象は windows、dotfiles、scripts、setup.sh とワークフロー自身の変更に限定しています。
