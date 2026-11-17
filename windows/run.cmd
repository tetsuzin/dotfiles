@echo off
setlocal
rem Windows entry point. Runs run.ps1 with PowerShell 7 when available,
rem otherwise with Windows PowerShell 5.1 (the first "prepare" has no pwsh yet).
rem Keep this file ASCII only: cmd reads it with the OEM code page.

where pwsh >nul 2>nul
if %ERRORLEVEL%==0 (set "PS=pwsh") else (set "PS=powershell")
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
exit /b %ERRORLEVEL%
