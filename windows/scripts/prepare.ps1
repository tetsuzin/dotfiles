#Requires -Version 5.1
<#
.SYNOPSIS
  Windows ホストの準備。winget で Git と mise を導入する。
.DESCRIPTION
  ./setup.sh prepare から呼ばれるほか、Git Bash が無い初回は PowerShell から直接実行する:
    powershell -ExecutionPolicy Bypass -File windows\scripts\prepare.ps1
  その他の OS パッケージと開発 CLI は ./setup.sh bootstrap (mise bootstrap) が導入する。
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Write-Step([string] $Message) { Write-Host "[STEP ] $Message" -ForegroundColor Green }
function Write-Info([string] $Message) { Write-Host "[INFO ] $Message" -ForegroundColor Green }
function Write-Warn([string] $Message) { Write-Host "[WARN ] $Message" -ForegroundColor Yellow }
function Fail([string] $Message) { Write-Host "[ERROR] $Message" -ForegroundColor Red; exit 1 }

# winget upgrade が「更新なし」で返す終了コード (APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE)。
$WingetNoUpdate = -1978335189

function Install-WingetPackage([string] $Id, [string] $Command) {
  if (Get-Command $Command -ErrorAction SilentlyContinue) {
    Write-Info "$Command は導入済みです: $((Get-Command $Command).Source)"
    return $false
  }
  Write-Info "$Id を winget で導入します"
  winget install --id $Id --exact --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) { Fail "$Id の導入に失敗しました (exit $LASTEXITCODE)" }
  return $true
}

function Update-WingetPackage([string] $Id) {
  winget upgrade --id $Id --exact --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $WingetNoUpdate) { return }
  Fail "$Id の更新に失敗しました (exit $LASTEXITCODE)"
}

$principal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if ($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Fail '管理者権限では実行しないでください。インストーラが必要な場合は UAC で個別に昇格します'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Fail 'winget が見つかりません。Microsoft Store から「アプリ インストーラー」を導入してください'
}

Write-Step 'シンボリックリンクの作成権限の確認'
$devMode = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devMode -eq 1) {
  Write-Info '開発者モードが有効です。dotfiles をシンボリックリンクで配置できます'
} else {
  Write-Warn '開発者モードが無効です。設定 > システム > 開発者向け で有効にしないと bootstrap の dotfiles 配置に失敗します'
}

Write-Step 'Git for Windows の導入'
# setup.sh は Git Bash で動くため、Git は bootstrap より前に必要。
$installedGit = Install-WingetPackage -Id 'Git.Git' -Command 'git'

Write-Step 'mise の導入'
# 公式が Windows で推奨する winget を使う。更新も winget に任せ、mise self-update は使わない。
$mise = Get-Command mise -ErrorAction SilentlyContinue
if ($mise -and $mise.Source -notlike "$env:LOCALAPPDATA\Microsoft\WinGet\*") {
  Write-Warn "winget 以外で導入された mise が PATH にあります: $($mise.Source)"
  Write-Warn '1 台に 1 つの導入方法に揃えてください (例: scoop uninstall mise)。古い方が実行されることがあります'
}
$installedMise = Install-WingetPackage -Id 'jdx.mise' -Command 'mise'
if (-not $installedMise) {
  Write-Info 'mise を winget で更新します'
  Update-WingetPackage -Id 'jdx.mise'
}

Write-Step '準備が完了しました'
if ($installedGit -or $installedMise) {
  Write-Info 'PATH の変更を反映するため、新しいターミナルを開いてください'
}
Write-Info '続けて Git Bash で ./setup.sh bootstrap を実行してください'
