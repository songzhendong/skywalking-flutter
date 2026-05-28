@echo off
cd /d "%~dp0.."
git add -A
for /f %%i in ('git rev-parse HEAD') do set PARENT=%%i
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -p %PARENT% -m "chore: release 0.1.2 (pub.dev score fixes)" > "%TEMP%\swf-pub.txt"
set /p COMMIT=<"%TEMP%\swf-pub.txt"
git reset --hard %COMMIT%
git push origin main
exit /b %ERRORLEVEL%
