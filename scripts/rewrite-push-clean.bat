@echo off
cd /d "%~dp0.."
git checkout --orphan main-clean
git add -A
for /f %%i in ('git write-tree') do set TREE=%%i
git commit-tree %TREE% -F "%~dp0commit-msg-clean.txt" > "%TEMP%\swf-commit.txt"
set /p COMMIT=<"%TEMP%\swf-commit.txt"
git reset --hard %COMMIT%
git branch -D main 2>nul
git branch -m main
git push -f origin main
exit /b %ERRORLEVEL%
