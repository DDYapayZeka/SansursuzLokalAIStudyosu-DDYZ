# scripts/reset/reset.ps1
# Resets portable app dependencies/builds while preserving user models and outputs.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir   = Split-Path -Parent (Split-Path -Parent $scriptDir)
$appDir    = Join-Path $rootDir "app"

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host "   Sansursuz Lokal AI Studyosu - DD:YZ sifirlaniyor..." -ForegroundColor Yellow
Write-Host "  ============================================================" -ForegroundColor Yellow
Write-Host ""

# Delete portable tools/runtime folder
$toolsDir = Join-Path $appDir "tools"
if (Test-Path $toolsDir) {
    Write-Host "   >> Removing portable tools/runtime folder..." -ForegroundColor Cyan
    Remove-Item $toolsDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Delete backend
$backendDir = Join-Path $appDir "backend"
if (Test-Path $backendDir) {
    Write-Host "   >> Removing image backend binaries..." -ForegroundColor Cyan
    Remove-Item $backendDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "      Preserving source workers in scripts/workers." -ForegroundColor DarkGray
}

# Delete llama.cpp backend
$llmBackendDir = Join-Path $appDir "llm-backend"
if (Test-Path $llmBackendDir) {
    Write-Host "   >> Removing llama.cpp text backend binaries..." -ForegroundColor Cyan
    Remove-Item $llmBackendDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Delete whisper.cpp backend
$speechBackendDir = Join-Path $appDir "speech-backend"
if (Test-Path $speechBackendDir) {
    Write-Host "   >> Removing whisper.cpp speech backend binaries..." -ForegroundColor Cyan
    Remove-Item $speechBackendDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Delete Kokoro TTS runtime dependencies
$ttsRuntimeDir = Join-Path $appDir "tts-runtime"
if (Test-Path $ttsRuntimeDir) {
    Write-Host "   >> Removing Kokoro TTS runtime dependencies..." -ForegroundColor Cyan
    Remove-Item $ttsRuntimeDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Delete dist
$distDir = Join-Path $appDir "dist"
if (Test-Path $distDir) {
    Write-Host "   >> Removing dist/ build folder..." -ForegroundColor Cyan
    Remove-Item $distDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Preserve image models
$modelsDir = Join-Path $appDir "models"
if (Test-Path $modelsDir) {
    Write-Host "   >> Preserving image models in app/models." -ForegroundColor Cyan
}

# Preserve text models
$llmModelsDir = Join-Path $appDir "llm-models"
if (Test-Path $llmModelsDir) {
    Write-Host "   >> Preserving text models in app/llm-models." -ForegroundColor Cyan
}

# Preserve speech models
$speechModelsDir = Join-Path $appDir "speech-models"
if (Test-Path $speechModelsDir) {
    Write-Host "   >> Preserving speech models in app/speech-models." -ForegroundColor Cyan
}

# Preserve TTS models
$ttsModelsDir = Join-Path $appDir "tts-models"
if (Test-Path $ttsModelsDir) {
    Write-Host "   >> Preserving TTS models in app/tts-models." -ForegroundColor Cyan
}

# Preserve generated image outputs
$outputsDir = Join-Path $appDir "outputs"
if (Test-Path $outputsDir) {
    Write-Host "   >> Preserving generated image outputs in app/outputs." -ForegroundColor Cyan
}

# Preserve chat history
$chatHistoryDir = Join-Path $appDir "chat-history"
if (Test-Path $chatHistoryDir) {
    Write-Host "   >> Preserving chat history in app/chat-history." -ForegroundColor Cyan
}

# Preserve transcriptions
$transcriptionsDir = Join-Path $appDir "transcriptions"
if (Test-Path $transcriptionsDir) {
    Write-Host "   >> Preserving speech transcripts in app/transcriptions." -ForegroundColor Cyan
}

# Preserve TTS outputs/cache
$ttsOutputsDir = Join-Path $appDir "tts-outputs"
if (Test-Path $ttsOutputsDir) {
    Write-Host "   >> Preserving TTS outputs in app/tts-outputs." -ForegroundColor Cyan
}
$ttsCacheDir = Join-Path $appDir "tts-cache"
if (Test-Path $ttsCacheDir) {
    Write-Host "   >> Preserving TTS model cache in app/tts-cache." -ForegroundColor Cyan
}

# Preserve OpenVINO models
$openVinoModelsDir = Join-Path $appDir "openvino-models"
if (Test-Path $openVinoModelsDir) {
    Write-Host "   >> Preserving OpenVINO models in app/openvino-models." -ForegroundColor Cyan
}

# Delete all frontend dependency folders, including platform-specific copies
$frontendDir = Join-Path $appDir "frontend"
Get-ChildItem $frontendDir -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -eq "node_modules" -or $_.Name -like "node_modules_*" } |
    ForEach-Object {
        Write-Host "   >> Removing frontend $($_.Name)..." -ForegroundColor Cyan
        Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

$activeOsFile = Join-Path $frontendDir ".active_modules_os"
if (Test-Path $activeOsFile) {
    Write-Host "   >> Removing frontend platform marker..." -ForegroundColor Cyan
    Remove-Item $activeOsFile -Force -ErrorAction SilentlyContinue
}


# Delete package-lock.json in frontend
$lockFile = Join-Path $appDir "frontend\package-lock.json"
if (Test-Path $lockFile) {
    Write-Host "   >> Removing frontend package-lock.json..." -ForegroundColor Cyan
    Remove-Item $lockFile -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host "   Reset complete. Models, generated images, chat history, transcripts, TTS outputs, TTS cache, and OpenVINO models were preserved." -ForegroundColor Green
Write-Host "  ============================================================" -ForegroundColor Green
Write-Host ""
Read-Host "  Press Enter to close..."
