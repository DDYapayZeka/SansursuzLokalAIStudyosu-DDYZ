# Sansursuz Lokal AI Studyosu - DD:YZ - Kokoro TTS setup for Windows

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent (Split-Path -Parent $scriptDir)
$appDir = Join-Path $rootDir "app"
$toolsDir = Join-Path $appDir "tools"
$nodeDir = Join-Path $toolsDir "node-win"
$nodeExe = Join-Path $nodeDir "node.exe"
$npmCmd = Join-Path $nodeDir "npm.cmd"
$runtimeDir = Join-Path $appDir "tts-runtime"
$modelsDir = Join-Path $appDir "tts-models"
$outputsDir = Join-Path $appDir "tts-outputs"
$cacheDir = Join-Path $appDir "tts-cache"

function Print-OK { param([string]$m); Write-Host "   OK  $m" -ForegroundColor Green }
function Print-Info { param([string]$m); Write-Host "   >>  $m" -ForegroundColor Cyan }
function Print-Fail { param([string]$m); Write-Host "   XX  $m" -ForegroundColor Red }

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host "   Setting up Kokoro ONNX Text-to-Speech runtime" -ForegroundColor Cyan
Write-Host "  ============================================================" -ForegroundColor Cyan
Write-Host ""

New-Item -ItemType Directory -Force -Path $runtimeDir, $modelsDir, $outputsDir, $cacheDir | Out-Null

if (-not (Test-Path $nodeExe) -or -not (Test-Path $npmCmd)) {
    Print-Fail "Portable Node.js is missing. Run scripts/setup/setup.ps1 first."
    exit 1
}

$packageJson = Join-Path $runtimeDir "package.json"
if (-not (Test-Path $packageJson)) {
    '{"private":true,"type":"module","dependencies":{"kokoro-js":"^1.2.1"}}' | Out-File -FilePath $packageJson -Encoding utf8
}

Push-Location $runtimeDir
$oldPath = $env:PATH
try {
    $env:PATH = "$nodeDir;$env:PATH"
    Print-Info "Installing kokoro-js into app/tts-runtime..."
    & $npmCmd install --prefer-offline --loglevel=error
    if ($LASTEXITCODE -ne 0) {
        Print-Fail "kokoro-js install failed."
        exit 1
    }
} finally {
    $env:PATH = $oldPath
    Pop-Location
}

Print-OK "Kokoro TTS runtime is ready."
