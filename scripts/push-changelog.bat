@echo off
cd /d "%~dp0.."
git add CHANGELOG.md
for /f %%i in ('git rev-parse HEAD') do set PARENT=%%i
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -p %PARENT% -m "docs: remove 0.1.1 changelog entry" > "%TEMP%\swf-cl.txt"
set /p COMMIT=<"%TEMP%\swf-cl.txt"
git reset --hard %COMMIT%
git push origin main
exit /b %ERRORLEVEL%
