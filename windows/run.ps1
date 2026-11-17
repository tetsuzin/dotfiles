#Requires -Version 5.1
# Windows のセットアップ本体。cmd、PowerShell、Windows Terminal からは run.cmd 経由で実行する。
# PowerShell 7 が無い初回の prepare でも動くよう、Windows PowerShell 5.1 で動く書き方にする。
$ErrorActionPreference = 'Stop'

function Show-Usage {
  Write-Host @'
Usage: .\run.cmd <command> [mise bootstrap のオプション...]

Commands:
  prepare    ホストの準備 (scoop と mise 本体)
  bootstrap  環境の適用と dotfiles の配置
  update     mise 本体、宣言した winget / scoop パッケージ、mise ツールを更新して適用
  link       dotfiles の配置のみ

bootstrap / update / link の残りの引数は mise bootstrap にそのまま渡します。
  --dry-run         変更予定を表示する
  --force-dotfiles  競合する dotfiles の置き換えを許可する
'@
}

# mise を実行し、失敗したらその終了コードで止める。
function Invoke-Mise {
  & mise @args
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# bootstrap / update / link 共通。mise を確認し、このディレクトリの設定を trust する。
function Enter-Environment {
  $env:Path = "$env:USERPROFILE\.local\bin;$env:Path"
  if (-not (Get-Command mise -ErrorAction SilentlyContinue)) {
    throw 'mise が見つかりません。先に .\run.cmd prepare を実行してください'
  }
  # run.cmd の実行はこの checkout の設定を適用する明示的な操作。
  # dry-run でも trust 状態だけは記録するが、ホスト構成は変更しない。
  Set-Location $PSScriptRoot
  Invoke-Mise trust mise.toml
}

# scoop と mise (公式スクリプト) を導入する。
# Git は clone の時点で必要なため、ここでは扱わず scoop の宣言 (packages.toml) で管理する。
function Invoke-Prepare {
  $devMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
  if ($devMode -ne 1) {
    Write-Warning '開発者モードが無効です。dotfiles をシンボリックリンクで配置するには 設定 > システム > 開発者向け で有効にしてください'
  }

  if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
  }
  # packages.toml が参照するバケット。mise はバケットを追加しないためここで行う。
  $scoopRoot = if ($env:SCOOP) { $env:SCOOP } else { "$env:USERPROFILE\scoop" }
  if (-not (Test-Path "$scoopRoot\buckets\extras")) {
    scoop bucket add extras
  }

  # Linux と同じく、公式スクリプトで ~\.local\bin に独立した mise を導入する。
  # 導入済みなら触らない。更新は update と self_update.auto が担う。
  # スクリプトはユーザーの Path に ~\.local\bin を追加する。
  $mise = "$env:USERPROFILE\.local\bin\mise.exe"
  if (-not (Test-Path $mise)) {
    Invoke-RestMethod -Uri 'https://mise.run/powershell' | Invoke-Expression
  }
  if (-not (Test-Path $mise)) { throw 'mise の導入に失敗しました' }
  $other = Get-Command mise -ErrorAction SilentlyContinue | Where-Object { $_.Source -ne $mise }
  if ($other) {
    Write-Warning "別の方法で導入された mise が PATH にあります: $($other.Source)。1 台に 1 つの導入方法に揃えてください"
  }

  Write-Host '準備が完了しました。新しいターミナルを開き、.\run.cmd bootstrap を実行してください'
}

$command = if ($args.Count -gt 0) { $args[0] } else { '' }
$rest = @(if ($args.Count -gt 1) { $args[1..($args.Count - 1)] })
$dryRun = $rest -contains '--dry-run'

switch ($command) {
  'prepare' { Invoke-Prepare }
  'bootstrap' {
    Enter-Environment
    Invoke-Mise bootstrap @rest
    if (-not $dryRun) { Write-Host '適用が完了しました。新しい PowerShell を起動してください' }
  }
  'link' {
    Enter-Environment
    Invoke-Mise bootstrap --only dotfiles @rest
    if (-not $dryRun) { Write-Host '配置が完了しました。新しい PowerShell を起動してください' }
  }
  'update' {
    Enter-Environment
    # プラグインの更新は含めない。clone が壊れていても本体の更新を止めないため。
    Invoke-Mise self-update --yes --no-plugins
    Invoke-Mise bootstrap --update @rest
    Invoke-Mise bootstrap packages upgrade
    Invoke-Mise upgrade
    Write-Host '更新が完了しました。新しい PowerShell を起動してください'
  }
  { $_ -in '-h', '--help' } { Show-Usage }
  default {
    Show-Usage
    if ($command) { Write-Host "[ERROR] 不明なコマンドです: $command" }
    exit 1
  }
}
