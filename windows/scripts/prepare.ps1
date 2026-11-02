#Requires -Version 5.1
# Windows ホストの準備。scoop と mise (公式スクリプト) を導入する。
# Git は clone の時点で必要なため、ここでは扱わず scoop の宣言 (packages.toml) で管理する。
# 入口は setup.cmd prepare。直接実行する場合: powershell -ExecutionPolicy Bypass -File windows\scripts\prepare.ps1
$ErrorActionPreference = 'Stop'


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

# Linux の prepare.sh と同じく、公式スクリプトで ~\.local\bin に独立した mise を導入する。
# 導入済みなら self-update で最新版にする。スクリプトはユーザーの Path に ~\.local\bin を追加する。
$mise = "$env:USERPROFILE\.local\bin\mise.exe"
if (Test-Path $mise) {
  & $mise self-update --yes
} else {
  Invoke-RestMethod -Uri 'https://mise.run/powershell' | Invoke-Expression
}
if (-not (Test-Path $mise)) { throw 'mise の導入に失敗しました' }
$other = Get-Command mise -ErrorAction SilentlyContinue | Where-Object { $_.Source -ne $mise }
if ($other) {
  Write-Warning "別の方法で導入された mise が PATH にあります: $($other.Source)。1 台に 1 つの導入方法に揃えてください"
}

Write-Host '準備が完了しました。新しいターミナルを開き、.\setup.cmd bootstrap を実行してください'
