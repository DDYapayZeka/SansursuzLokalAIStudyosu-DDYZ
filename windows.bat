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
if exist "%CUDA_BACKEND%" goto :launch
if exist "%VULKAN_BACKEND%" goto :launch
set SETUP_REASON=Yuklu motor dosyasi bulunamadi.
goto :run_setup

:run_setup
echo.
echo  ============================================================
type "%~dp0logo.txt"
echo.
echo       Sansursuz Lokal AI Studyosu - DD:YZ   ^|  %SETUP_MODE%
echo  ============================================================
echo.
if "%SETUP_MODE%"=="Ilk Kurulum" (
    echo  Bu ilk calistirmeniz gibi gorunuyor. Otomatik olarak kuruluyor...
) else (
    echo  Sansursuz Lokal AI Studyosu - DD:YZ baslatilmadan once hizli bir onarima ihtiyac duyuyor.
)
if not "%SETUP_REASON%"=="" echo  Neden: %SETUP_REASON%
echo  Modeller kurulum sirasinda indirilmez. Uygulama icinden indirin veya ice aktarin.
echo.
echo  Devam etmek icin herhangi bir tusa basin, veya iptal etmek icin Ctrl+C tusuna basin.
pause >nul

:: Clear old managed backend processes before setup so app/tools/node-win can be replaced.
:: Do not kill the frontend port; launch will select a free frontend port automatically.
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8080 "') do taskkill /f /pid %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":%LLM_PORT% "') do taskkill /f /pid %%a >nul 2>nul

powershell -ExecutionPolicy Bypass -File "%SETUP%"
if errorlevel 1 (
    echo.
    echo  [HATA] Kurulum basarisiz oldu. Lutfen yukaridaki ciktiyi kontrol edin.
    pause
    exit /b 1
)

:: After setup, continue to launch
goto :launch

:: -- Launch -------------------------------------------------------------------
:launch
echo.
echo  ============================================================
type "%~dp0logo.txt"
echo.
echo       Sansursuz Lokal AI Studyosu - DD:YZ   ^|  Baslatiliyor...
echo  ============================================================
echo.

set "REQUESTED_FRONTEND_PORT=%FRONTEND_PORT%"
call :resolve_frontend_port
if errorlevel 1 exit /b 1
if not "%FRONTEND_PORT%"=="%REQUESTED_FRONTEND_PORT%" echo  Arayuz portu %REQUESTED_FRONTEND_PORT% mesgul; yerine %FRONTEND_PORT% kullaniliyor.

:: Clear managed backend ports to prevent stale API conflicts.
echo  Arka plan portu 8080 ve metin portu %LLM_PORT% temizleniyor...
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":8080 "') do taskkill /f /pid %%a >nul 2>nul
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":%LLM_PORT% "') do taskkill /f /pid %%a >nul 2>nul

:: Start frontend server + backend manager (serve.cjs manages sd-vulkan.exe)
echo  Sansursuz Lokal AI Studyosu - DD:YZ baslatiliyor...
echo  Tarayici http://localhost:%FRONTEND_PORT% adresinde aciliyor...
start /b cmd /c "timeout /t 2 >nul && start http://localhost:%FRONTEND_PORT%"

echo.
echo  ============================================================
echo   Calisiyor!
echo   Web Arayuzu:     http://localhost:%FRONTEND_PORT%
echo   GPU API:         Uygulama tarafindan otomatik secilir (8080 portunda baslar)
echo   Metin API:       Bir GGUF modeli yuklendiginde baslar (port %LLM_PORT%)
echo   Ses Tanima:      Uygulama tarafindan yerel olarak yonetilir
echo   Metinden Sese:   Uygulama tarafindan yerel olarak yonetilir
echo.
echo   Tum servisleri durdurmak icin bu pencerede Ctrl+C tuslarina basin.
echo  ============================================================
echo.

"%NODE%" "%SERVE%"
exit /b %ERRORLEVEL%

:resolve_frontend_port
call :is_port_available "%FRONTEND_PORT%"
if "%PORT_AVAILABLE%"=="1" exit /b 0

for /L %%p in (1421,1,1499) do (
    if not "%%p"=="%FRONTEND_PORT%" (
        call :is_port_available "%%p"
        if "!PORT_AVAILABLE!"=="1" (
            set "FRONTEND_PORT=%%p"
            exit /b 0
        )
    )
)

echo  [HATA] Bos arayuz portu bulunamadi. %FRONTEND_PORT% ve 1421-1499 portlari denendi.
exit /b 1

:is_port_available
set "PORT_AVAILABLE=1"
for /f "tokens=5" %%a in ('netstat -aon 2^>nul ^| findstr ":%~1 " ^| findstr /I "LISTENING"') do (
    set "PORT_AVAILABLE=0"
)
exit /b 0
