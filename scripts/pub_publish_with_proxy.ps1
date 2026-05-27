# Publish to pub.dev (run after pub_login_with_proxy.ps1 succeeds).
param(
    [int]$ProxyPort = 7890
)

$ErrorActionPreference = "Stop"
$proxy = "http://127.0.0.1:$ProxyPort"

$env:PUB_HOSTED_URL = "https://pub.dev"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.googleapis.com"
$env:HTTP_PROXY = $proxy
$env:HTTPS_PROXY = $proxy

Push-Location (Split-Path -Parent $PSScriptRoot)
dart pub publish --force
Pop-Location
