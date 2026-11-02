#Requires -Version 5.1
# Windows ホストの準備。scoop と mise (winget) を導入する。
# Git は clone の時点で必要なため、ここでは扱わず scoop の宣言 (packages.toml) で管理する。
# 初回は PowerShell から直接実行する: powershell -ExecutionPolicy Bypass -File windows\scripts\prepare.ps1
$ErrorActionPreference = 'Stop'

# winget が「更新なし」「導入済み」で返す終了コード。
$WingetNoUpdate = -1978335189

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

# 公式が Windows で推奨する winget を使う。導入済みなら更新も兼ねる。
winget install --id jdx.mise --exact --accept-source-agreements --accept-package-agreements
if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $WingetNoUpdate) {
  throw "mise の導入に失敗しました (exit $LASTEXITCODE)"
}

Write-Host '準備が完了しました。新しいターミナルを開き、Git Bash で ./setup.sh bootstrap を実行してください'
