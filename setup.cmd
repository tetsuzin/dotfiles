@echo off
setlocal
rem Windows entry point. "prepare" runs in PowerShell because Git Bash may
rem not exist yet. Every other command is forwarded to setup.sh in Git Bash.
rem Keep this file ASCII only: cmd reads it with the OEM code page.

if /i "%~1"=="prepare" goto prepare

rem Locate Git Bash from the git executable so WSL's bash.exe is never used.
for /f "delims=" %%i in ('git --exec-path 2^>nul') do set "GITCORE=%%i"
if not defined GITCORE (
  echo [ERROR] git was not found. Run "setup.cmd prepare" first. 1>&2
  exit /b 1
)
set "GITBASH=%GITCORE:/=\%\..\..\..\bin\bash.exe"
if not exist "%GITBASH%" (
  echo [ERROR] Git Bash was not found: "%GITBASH%" 1>&2
  exit /b 1
)
"%GITBASH%" "%~dp0setup.sh" %*
exit /b %ERRORLEVEL%

:prepare
where pwsh >nul 2>nul
if %ERRORLEVEL%==0 (set "PS=pwsh") else (set "PS=powershell")
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0windows\scripts\prepare.ps1"
exit /b %ERRORLEVEL%