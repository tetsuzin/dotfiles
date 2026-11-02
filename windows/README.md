# Windows セットアップ

Windows 11 を対象に、mise と winget、scoop で環境を構築します。Linux と同じ mise bootstrap の仕組みを使い、Nix は不要です。

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

`prepare` は scoop 本体と extras バケットが無ければ導入し、mise を winget で導入または更新します。公式が Windows で推奨する winget に揃え、`mise self-update` は使いません。winget の mise は公式リリースより数日遅れることがあります。必要バージョンは 2026.10.12 以上で、`mise.toml` の `min_version` が検査します。

`bootstrap` は winget / scoop パッケージ、dotfiles、ツールの順に適用します。管理者権限は不要ですが、インストーラが UAC プロンプトを出すことがあります。dotfiles はシンボリックリンクで配置するため、開発者モード (設定 > システム > 開発者向け) を有効にしておきます。リポジトリの設定はこの操作で mise に trust されます。

## 設定の管理先

- `mise.toml`: 必要バージョンと共通ツール設定の読み込みだけ。`mise/conf.d/*.toml` は同じディレクトリの設定として自動で読み込まれ、このファイルの trust に含まれます。
- `mise/conf.d/packages.toml`: OS パッケージ。winget は PowerShell 7、Windows Terminal、mise 本体。scoop は Git、7-Zip、less、sudo、zellij などユーザー領域の CLI と GUI ツール。extras バケットのものは `scoop:extras/<name>` と書きますが、scoop は名前だけで照合するためバケットは prepare.ps1 が追加します。
- `mise/conf.d/dotfiles.toml`: ホームに配置するシンボリックリンク。`~` は `C:\Users\<name>` に解決され、リンク元の相対パスはこのファイルの位置が基準です。
- `dotfiles/HOME/.config/mise/conf.d/windows.toml`: Windows の CLI ツール。ホームにも配置され、どのディレクトリでも利用できます。
- `dotfiles/HOME/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`: PowerShell 7 のプロファイル。mise の activate と starship の初期化を含みます。
- `../common/dotfiles/HOME/.config/mise/config.toml`: 従来からの共通ランタイム・ツール。

PowerShell・Windows Terminal などシステム寄りの基盤は winget、Git や圧縮ツールなどユーザー領域の基盤は scoop、開発 CLI は mise が担当します。Windows 向けビルドが無いツール (btop、krew、aws-cli など) は Linux の設定にだけ置きます。mise は `[bootstrap.mise_shell_activate]` で PowerShell に対応していないため、activate はプロファイルに直接書いています。

Git の設定は `~/.config/git/config` に配置します。`~/.gitconfig` が既にある場合は両方が読まれ、重複する項目は `~/.gitconfig` が優先されます。マシン固有の設定 (ghq の root や safe.directory など) はそのまま `~/.gitconfig` に残せます。

## 更新と確認

```powershell
.\setup.cmd bootstrap --dry-run
.\setup.cmd bootstrap --update
.\setup.cmd bootstrap --link-only
```

通常の適用は不足しているパッケージを導入します。`--update` は宣言した winget / scoop パッケージと mise ツールを更新します。scoop でバージョンを固定した項目は更新されません。`--update-only` は macOS の flake.lock 更新用で、Windows では使用しません。

mise は `~` を常に実際のユーザープロファイルに解決するため、Linux のテストのような一時ホームでの隔離は行えません。変更内容は `--dry-run` か、`mise -C windows bootstrap status` と `mise -C windows dotfiles diff` で事前に確認します。

## 既存の環境から移行

1. `mise -C windows bootstrap status` で、winget / scoop パッケージと dotfiles の現状を確認します。scoop で入れたものは winget からは見えず、その逆も同じなので、宣言したマネージャと実際の導入元が違うものは二重に導入されます。先に整理するか、`packages.toml` の該当行を直します。
2. `.\setup.cmd prepare` を実行します。scoop 版の mise が入っている場合は、winget 版と重複しないよう `scoop uninstall mise` で外します。導入済みのツールのデータ (`~\AppData\Local\mise`) は残るため再ダウンロードは不要です。
3. `.\setup.cmd bootstrap --dry-run` で変更予定を確認し、`.\setup.cmd bootstrap` を実行します。`~/.config/starship.toml`、`~/.claude/settings.json`、`~/.config/mise/config.toml`、PowerShell プロファイルなどの既存ファイルは自動で上書きしません。退避後に必要な場合のみ `--link-force=y` を指定します。
4. 新しい PowerShell で `Get-Command mise`、`mise doctor`、`mise ls` を確認します。shims が古い mise を指している場合は `mise reshim` を実行します。
5. mise の `[tools]` に移したツール (act、gh、jq、shfmt、starship など) は scoop 側を `scoop uninstall` で外します。残したままでも動きますが、PATH の順序で古い方が実行されることがあります。

## 検証

`.github/workflows/windows-setup.yml` は Windows ランナーで、シェルの構文チェック、設定ファイルの読み込み、ツールの導入 dry-run、dotfiles の dry-run を実行します。main への push と PR のときだけ動き、対象は windows、common/dotfiles、scripts、setup.sh とワークフロー自身の変更に限定しています。
