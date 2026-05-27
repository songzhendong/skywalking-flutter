# Login to pub.dev via dart pub (use when browser succeeds but CLI times out).
# Edit $proxyPort if your VPN uses another port (common: 7890, 10809, 1080).
param(
    [int]$ProxyPort = 7890
)

$ErrorActionPreference = "Stop"
$proxy = "http://127.0.0.1:$ProxyPort"

$env:PUB_HOSTED_URL = "https://pub.dev"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"
$env:HTTP_PROXY = $proxy
$env:HTTPS_PROXY = $proxy
$env:NO_PROXY = "localhost,127.0.0.1"

Write-Host "Using proxy: $proxy" -ForegroundColor Cyan
Write-Host "NO_PROXY=$env:NO_PROXY (localhost OAuth callback)" -ForegroundColor Cyan
Write-Host ""
Write-Host "1) Run: dart pub login" -ForegroundColor Yellow
Write-Host "2) Open the Google URL in browser, click Allow" -ForegroundColor Yellow
Write-Host "3) When browser shows Pub Authorized Successfully, return here" -ForegroundColor Yellow
Write-Host ""

Push-Location (Split-Path -Parent $PSScriptRoot)
dart pub login
if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }

Write-Host ""
Write-Host "Tokens:" -ForegroundColor Green
dart pub token list
Pop-Location
