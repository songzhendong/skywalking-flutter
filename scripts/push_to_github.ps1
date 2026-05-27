# Sync this directory to https://github.com/songzhendong/skywalking-flutter
param(
    [string]$Message = "chore: sync skywalking_flutter"
)

$ErrorActionPreference = "Stop"
$repoUrl = "https://github.com/songzhendong/skywalking-flutter.git"
$srcRoot = Split-Path -Parent $PSScriptRoot
$work = Join-Path $env:TEMP "skywalking-flutter-push"

$excludeNames = @(".git", ".dart_tool", "build", ".idea")
$excludeSuffix = @(".iml")

if (Test-Path $work) {
    Push-Location $work
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    git pull --rebase origin main 2>&1 | ForEach-Object { Write-Host $_ }
    $ErrorActionPreference = $prevEap
    Pop-Location
} else {
    git clone $repoUrl $work
    if ($LASTEXITCODE -ne 0) { throw "git clone failed" }
}

Get-ChildItem $work -Force | Where-Object {
    $_.Name -ne ".git"
} | Remove-Item -Recurse -Force

Get-ChildItem $srcRoot -Force | Where-Object {
    $n = $_.Name
    if ($excludeNames -contains $n) { return $false }
    foreach ($s in $excludeSuffix) {
        if ($n.EndsWith($s)) { return $false }
    }
    return $true
} | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $work $_.Name) -Recurse -Force
}

Push-Location $work
git add -A
$status = git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to push." -ForegroundColor Yellow
    Pop-Location
    exit 0
}
git commit -m $Message
git push origin main
Pop-Location
Write-Host "Pushed: $repoUrl" -ForegroundColor Green
