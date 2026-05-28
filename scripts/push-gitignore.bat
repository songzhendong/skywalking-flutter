@echo off
cd /d "%~dp0.."
git add .gitignore
for /f %%i in ('git rev-parse HEAD') do set PARENT=%%i
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -p %PARENT% -m "chore: add .gitignore" > "%TEMP%\swf2.txt"
set /p COMMIT=<"%TEMP%\swf2.txt"
git reset --hard %COMMIT%
git push origin main
