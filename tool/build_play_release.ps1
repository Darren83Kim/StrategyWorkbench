param(
    [switch]$BuildApk,
    [switch]$ValidateOnly
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$envPath = Join-Path $projectRoot '.env'
$flutter = Join-Path $projectRoot '.tools\flutter-sdk\flutter\bin\flutter.bat'

if (-not (Test-Path -LiteralPath $envPath)) {
    throw 'Missing .env. Production AdMob values are required.'
}

if (-not (Test-Path -LiteralPath $flutter)) {
    throw 'Bundled Flutter SDK was not found.'
}

$envValues = @{}
foreach ($line in Get-Content -LiteralPath $envPath) {
    if ($line -match '^\s*([^#=]+?)\s*=\s*(.*?)\s*$') {
        $envValues[$matches[1]] = $matches[2].Trim('"').Trim("'")
    }
}

function Get-ProductionAdMobValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$Pattern
    )

    $value = $envValues[$Name]
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "Missing $Name in .env."
    }

    if ($value -like 'ca-app-pub-3940256099942544*' -or $value -notmatch $Pattern) {
        throw "$Name is not a valid production AdMob identifier."
    }

    return $value
}

$appId = Get-ProductionAdMobValue `
    -Name 'ADMOB_ANDROID_APP_ID' `
    -Pattern '^ca-app-pub-\d+~\d+$'
$bannerId = Get-ProductionAdMobValue `
    -Name 'ADMOB_ANDROID_BANNER_ID' `
    -Pattern '^ca-app-pub-\d+/\d+$'
$interstitialId = Get-ProductionAdMobValue `
    -Name 'ADMOB_ANDROID_INTERSTITIAL_ID' `
    -Pattern '^ca-app-pub-\d+/\d+$'

Write-Output 'Production AdMob configuration is valid.'
if ($ValidateOnly) {
    return
}

$target = if ($BuildApk) { 'apk' } else { 'appbundle' }
$arguments = @(
    'build',
    $target,
    '--release',
    '--no-tree-shake-icons',
    '--dart-define=STORE_VARIANT=personal',
    "--dart-define=ADMOB_ANDROID_APP_ID=$appId",
    "--dart-define=ADMOB_ANDROID_BANNER_ID=$bannerId",
    "--dart-define=ADMOB_ANDROID_INTERSTITIAL_ID=$interstitialId"
)

Push-Location $projectRoot
try {
    & $flutter @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Flutter release build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
}
