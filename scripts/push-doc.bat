@echo off
cd /d "%~dp0.."
git add doc/USAGE.md
for /f %%i in ('git rev-parse HEAD') do set PARENT=%%i
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -p %PARENT% -m "docs: remove thumbnail captions in USAGE.md" > "%TEMP%\swf-doc.txt"
set /p COMMIT=<"%TEMP%\swf-doc.txt"
git reset --hard %COMMIT%
git push origin main
exit /b %ERRORLEVEL%
