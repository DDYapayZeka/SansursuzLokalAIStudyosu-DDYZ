@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title Sansursuz Lokal AI Studyosu - DD:YZ
cd /d "%~dp0"

set APP=%~dp0app
set NODE=%APP%\tools\node-win\node.exe
set NPM=%APP%\tools\node-win\npm.cmd
set DIST=%APP%\dist\index.html
set SETUP=%~dp0scripts\setup\setup.ps1
set CUDA_BACKEND=%APP%\backend\win\cuda\sd-cuda.exe
set VULKAN_BACKEND=%APP%\backend\win\vulkan\sd-vulkan.exe
set LLM_CUDA_BACKEND=%APP%\llm-backend\win\cuda\llama-server.exe
set LLM_HIP_BACKEND=%APP%\llm-backend\win\hip\llama-server.exe
set LLM_VULKAN_BACKEND=%APP%\llm-backend\win\vulkan\llama-server.exe
set LLM_SYCL_BACKEND=%APP%\llm-backend\win\sycl\llama-server.exe
set LLM_CPU_BACKEND=%APP%\llm-backend\win\cpu\llama-server.exe
set SPEECH_BACKEND=%APP%\speech-backend\win\cpu\whisper-cli.exe
set TTS_RUNTIME=%APP%\tts-runtime\node_modules\kokoro-js
set SERVE=%~dp0scripts\server\serve.cjs
if "%FRONTEND_PORT%"=="" set FRONTEND_PORT=1420
if "%LLM_PORT%"=="" set LLM_PORT=10086
set SETUP_REASON=
set SETUP_MODE=Onarim

:: -- First-time setup check ----------------------------------------------------
if not exist "%APP%\tools\node-win" set SETUP_MODE=Ilk Kurulum
if not exist "%NODE%" (
    set SETUP_REASON=Tasinabilir Node.js eksik.
    goto :run_setup
)
if not exist "%NPM%" (
    set SETUP_REASON=Tasinabilir npm eksik.
    goto :run_setup
)
if not exist "%DIST%" (
    set SETUP_REASON=Arayuz derlemesi eksik.
    goto :run_setup
)
if not exist "%LLM_CUDA_BACKEND%" if not exist "%LLM_HIP_BACKEND%" if not exist "%LLM_VULKAN_BACKEND%" if not exist "%LLM_SYCL_BACKEND%" if not exist "%LLM_CPU_BACKEND%" (
    set SETUP_REASON=llama.cpp metin motoru eksik.
    goto :run_setup
)
if not exist "%SPEECH_BACKEND%" (
    set SETUP_REASON=whisper.cpp ses motoru eksik.
    goto :run_setup
)
if not exist "%TTS_RUNTIME%" (
    set SETUP_REASON=Kokoro metinden sese calisma zamani eksik.
    goto :run_setup
)
if not exist "%CUDA_BACKEND%" if not exist "%VULKAN_BACKEND%" (
    set SETUP_REASON=stable-diffusion gorsel motoru eksik.
    goto :run_setup
)

:: -- Launch -------------------------------------------------------------------
:launch
cls
if exist "%~dp0logo.txt" (
    type "%~dp0logo.txt"
)
echo.
echo   ============================================================
echo    Sansursuz Lokal AI Studyosu - DD:YZ
echo    Baslatiliyor... Tarayiciniz otomatik acilacak.
echo  ============================================================
echo.
echo   Tarayici acilmazsa su adrese gidin:
echo   http://localhost:%FRONTEND_PORT%
echo.
echo   Durdurmak icin bu pencereyi kapatin veya Ctrl+C tuslarina basin.
echo.

"%NODE%" "%SERVE%"
if %errorlevel% neq 0 (
    echo.
    echo [Hata] Sunucu beklenmedik bir sekilde sonlandi. Hata kodu: %errorlevel%
    pause
)
goto :eof

:: -- Run Setup ----------------------------------------------------------------
:run_setup
cls
if exist "%~dp0logo.txt" (
    type "%~dp0logo.txt"
)
echo.
echo   ============================================================
echo    Sansursuz Lokal AI Studyosu - DD:YZ   -  %SETUP_MODE%
echo   ============================================================
echo.
if defined SETUP_REASON (
    echo   Gerekce: %SETUP_REASON%
    echo.
)
echo   Kurulum baslatiliyor, lutfen bekleyin...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%SETUP%"
if %errorlevel% neq 0 (
    echo.
    echo   [XX] Kurulum basarisiz oldu. Lutfen yukaridaki hatalari inceleyin.
    echo.
    pause
    exit /b %errorlevel%
)

goto :launch
