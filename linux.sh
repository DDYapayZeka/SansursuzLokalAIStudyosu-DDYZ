#!/usr/bin/env bash
#
# Sansursuz Lokal AI Studyosu - DD:YZ - Linux Launcher
# Double-click or run: ./linux.sh
# Kullan --max-perf to enable ROCm backend downloads on Linux first setup.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/app"
PLATFORM="$(uname -s)"

if [[ "$PLATFORM" != "Linux" ]]; then
  echo "[Hata] Bu betik yalnizca Linux icindir. Lutfen macOS uzerinde ./mac.sh calistirin." >&2
  exit 1
fi

NODE_DIR="$APP_DIR/tools/node-linux"
NODE_BIN="$NODE_DIR/bin/node"
BACKEND_PATH="$APP_DIR/backend/linux/vulkan/sd-vulkan"
CPU_BACKEND_PATH="$APP_DIR/backend/linux/cpu/sd-cpu"
PLATFORM_LABEL="Linux"

DIST_INDEX="$APP_DIR/dist/index.html"
SETUP_SCRIPT="$SCRIPT_DIR/scripts/setup/setup.sh"
SERVE_SCRIPT="$SCRIPT_DIR/scripts/server/serve.cjs"

FRONTEND_PORT="${FRONTEND_PORT:-1420}"
LLM_PORT="${LLM_PORT:-10086}"
SETUP_REASON=""
SETUP_MODE="Onarim"
MAX_PERF_FLAG=""
SETUP_OPENVINO=0

is_port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return
  fi
  if command -v nc >/dev/null 2>&1; then
    nc -z 127.0.0.1 "$port" >/dev/null 2>&1
    return
  fi
  (echo >"/dev/tcp/127.0.0.1/$port") >/dev/null 2>&1
}

resolve_frontend_port() {
  local preferred="$1"
  local port

  if ! is_port_in_use "$preferred"; then
    echo "$preferred"
    return 0
  fi

  for ((port = 1421; port <= 1499; port += 1)); do
    if [[ "$port" == "$preferred" ]]; then
      continue
    fi
    if ! is_port_in_use "$port"; then
      echo "$port"
      return 0
    fi
  done

  echo "[Hata] Bos arayuz portu bulunamadi. Denendi $preferred and 1421-1499." >&2
  return 1
}

# Parse args
for arg in "$@"; do
  case "$arg" in
    --max-perf)
      MAX_PERF_FLAG="--max-perf"
      ;;
    --setup-openvino)
      SETUP_OPENVINO=1
      ;;
    *)
      echo "[Hata] Bilinmeyen secenek: $arg" >&2
      echo "Kullanim: ./linux.sh [--max-perf] [--setup-openvino]" >&2
      exit 1
      ;;
  esac
done

if [[ $SETUP_OPENVINO -eq 1 ]]; then
  bash "$SCRIPT_DIR/scripts/setup/setup-openvino-npu.sh"
fi

# -- Setup node_modules to avoid OS conflicts --------------------------------
FRONTEND_NODE_MODULES="$APP_DIR/frontend/node_modules"
LINUX_NODE_MODULES="$APP_DIR/frontend/node_modules_linux"
ACTIVE_OS_FILE="$APP_DIR/frontend/.active_modules_os"

# Attempt to create a test symlink to check if filesystem supports symlinks
USE_SYMLINKS=true
TEST_LINK="$APP_DIR/frontend/.test_symlink"
rm -f "$TEST_LINK"
if ln -s "node_modules_linux" "$TEST_LINK" 2>/dev/null; then
  rm -f "$TEST_LINK"
else
  USE_SYMLINKS=false
fi

if [ "$USE_SYMLINKS" = true ]; then
  if [[ -d "$FRONTEND_NODE_MODULES" && ! -L "$FRONTEND_NODE_MODULES" ]]; then
    echo "  >> Mevcut node_modules node_modules_linux konumuna tasiniliyor..."
    rm -rf "$LINUX_NODE_MODULES"
    mv "$FRONTEND_NODE_MODULES" "$LINUX_NODE_MODULES"
  fi
  rm -f "$FRONTEND_NODE_MODULES"
  mkdir -p "$LINUX_NODE_MODULES"
  ln -sf "node_modules_linux" "$FRONTEND_NODE_MODULES"
else
  # Fallback: Filesystem does not support symlinks (e.g. FAT32/exFAT)
  echo "  >> Dosya sistemi sembolik baglari desteklemiyor. Dizin takas yedegi kullaniliyor..."
  
  if [[ -L "$FRONTEND_NODE_MODULES" || -f "$FRONTEND_NODE_MODULES" ]]; then
    rm -f "$FRONTEND_NODE_MODULES"
  fi
  
  PREV_OS=""
  if [[ -f "$ACTIVE_OS_FILE" ]]; then
    PREV_OS=$(cat "$ACTIVE_OS_FILE")
  fi
  
  if [[ -d "$FRONTEND_NODE_MODULES" && "$PREV_OS" != "linux" ]]; then
    if [[ -n "$PREV_OS" ]]; then
      echo "  >> node_modules node_modules_ konumuna takas ediliyor$PREV_OS..."
      rm -rf "$APP_DIR/frontend/node_modules_$PREV_OS"
      mv "$FRONTEND_NODE_MODULES" "$APP_DIR/frontend/node_modules_$PREV_OS"
    else
      echo "  >> node_modules node_modules_windows olarak kaydediliyor..."
      rm -rf "$APP_DIR/frontend/node_modules_windows"
      mv "$FRONTEND_NODE_MODULES" "$APP_DIR/frontend/node_modules_windows"
    fi
  fi
  
  if [[ -d "$LINUX_NODE_MODULES" && ! -d "$FRONTEND_NODE_MODULES" ]]; then
    echo "  >> node_modules_linux takas ediliyor..."
    mv "$LINUX_NODE_MODULES" "$FRONTEND_NODE_MODULES"
  elif [[ ! -d "$FRONTEND_NODE_MODULES" ]]; then
    mkdir -p "$FRONTEND_NODE_MODULES"
  fi
  
  echo "linux" > "$ACTIVE_OS_FILE"
fi

# -- First-time setup check -------------------------------------------------
if [[ ! -d "$NODE_DIR" ]]; then
  SETUP_MODE="Ilk Kurulum"
fi

if [[ ! -x "$NODE_BIN" ]]; then
  SETUP_REASON="Tasinabilir Node.js (Linux) eksik."
fi

if [[ ! -f "$DIST_INDEX" ]]; then
  SETUP_REASON="On yuz derlemesi eksik."
fi

# At minimum we need CPU or Vulkan backend on Linux, and both CLI and server binaries must be executable
CPU_SERVER_PATH="$APP_DIR/backend/linux/cpu/sd-server-cpu"
VULKAN_SERVER_PATH="$APP_DIR/backend/linux/vulkan/sd-server-vulkan"
LLM_CUDA_PATH="$APP_DIR/llm-backend/linux/cuda/llama-server"
LLM_ROCM_PATH="$APP_DIR/llm-backend/linux/rocm/llama-server"
LLM_SYCL_PATH="$APP_DIR/llm-backend/linux/sycl/llama-server"
LLM_VULKAN_PATH="$APP_DIR/llm-backend/linux/vulkan/llama-server"
LLM_CPU_PATH="$APP_DIR/llm-backend/linux/cpu/llama-server"
SPEECH_BACKEND_PATH="$APP_DIR/speech-backend/linux/cpu/whisper-cli"
TTS_RUNTIME_PATH="$APP_DIR/tts-runtime/node_modules/kokoro-js"
if [[ ! -x "$CPU_BACKEND_PATH" || ! -x "$CPU_SERVER_PATH" ]] && [[ ! -x "$BACKEND_PATH" || ! -x "$VULKAN_SERVER_PATH" ]]; then
  SETUP_REASON="Linux arka uc ikilileri eksik veya calistirilabilir degil."
fi
if [[ ! -x "$LLM_CUDA_PATH" && ! -x "$LLM_ROCM_PATH" && ! -x "$LLM_SYCL_PATH" && ! -x "$LLM_VULKAN_PATH" && ! -x "$LLM_CPU_PATH" ]]; then
  SETUP_REASON="Linux llama.cpp metin arka ucu eksik veya calistirilabilir degil."
fi
if [[ ! -x "$SPEECH_BACKEND_PATH" ]]; then
  SETUP_REASON="Linux whisper.cpp konusma arka ucu eksik veya calistirilabilir degil."
fi
if [[ ! -d "$TTS_RUNTIME_PATH" ]]; then
  SETUP_REASON="Kokoro metinden sese calmasi zamani eksik."
fi

if [[ -n "$SETUP_REASON" ]]; then
  echo ""
  echo "  ============================================================"
  cat "$SCRIPT_DIR/logo.txt"
  echo ""
  echo "       Sansursuz Lokal AI Studyosu - DD:YZ   |  $PLATFORM_LABEL $SETUP_MODE"
  echo "  ============================================================"
  echo ""
  if [[ "$SETUP_MODE" == "Ilk Kurulum" ]]; then
    echo "  Bu, Linux uzerinde ilk calistirmaniz gibi gorunuyor. Otomatik olarak kuruluyor..."
  else
    echo "  Sansursuz Lokal AI Studyosu - DD:YZ baslatilmadan once hizli bir onarima ihtiyac duyuyor."
  fi
  echo "  Reason: $SETUP_REASON"
  echo "  Modeller kurulum sirasinda indirilmez. Uygulama icinden indirin veya ice aktarin."
  echo ""
  read -rp "  Devam etmek icin Enter'e basin, veya iptal etmek icin Ctrl+C tusuna basin."

  # Clear managed backend ports before setup. Do not kill the frontend port;
  # launch will select a free frontend port automatically.
  if command -v lsof >/dev/null 2>&1; then
    lsof -t -i:8080 -i:"${LLM_PORT}" | xargs kill -9 >/dev/null 2>&1 || true
  elif command -v fuser >/dev/null 2>&1; then
    fuser -k "8080/tcp" >/dev/null 2>&1 || true
    fuser -k "${LLM_PORT}/tcp" >/dev/null 2>&1 || true
  fi

  if ! bash "$SETUP_SCRIPT" $MAX_PERF_FLAG; then
    echo ""
    echo "  [Hata] Kurulum basarisiz oldu. Lutfen yukaridaki ciktiyi kontrol edin."
    read -rp "  Kapatmak icin Enter'e basin..."
    exit 1
  fi
fi

# -- Launch -----------------------------------------------------------------
clear 2>/dev/null || true
echo ""
echo "  ============================================================"
cat "$SCRIPT_DIR/logo.txt"
echo ""
echo "       Sansursuz Lokal AI Studyosu - DD:YZ   |  Baslatiliyor..."
echo "  ============================================================"
echo ""

REQUESTED_FRONTEND_PORT="$FRONTEND_PORT"
FRONTEND_PORT="$(resolve_frontend_port "$REQUESTED_FRONTEND_PORT")"
if [[ "$FRONTEND_PORT" != "$REQUESTED_FRONTEND_PORT" ]]; then
  echo "  Arayuz portu ${REQUESTED_FRONTEND_PORT} mesgul; su kullaniliyor ${FRONTEND_PORT} yerine."
fi

# Clear managed backend ports
if command -v lsof >/dev/null 2>&1; then
  lsof -t -i:8080 -i:"${LLM_PORT}" | xargs kill -9 >/dev/null 2>&1 || true
elif command -v fuser >/dev/null 2>&1; then
  fuser -k "8080/tcp" >/dev/null 2>&1 || true
  fuser -k "${LLM_PORT}/tcp" >/dev/null 2>&1 || true
fi

# Start the server
echo "  Sansursuz Lokal AI Studyosu - DD:YZ baslatiliyor..."
export PATH="$NODE_DIR/bin:$PATH"
export FRONTEND_PORT="$FRONTEND_PORT"

# Run server in background and capture PID
"$NODE_BIN" "$SERVE_SCRIPT" &
SERVER_PID=$!

# Wait for server to be ready
sleep 2

# Open browser
if command -v xdg-open >/dev/null 2>&1; then
  echo "  Tarayici su adreste aciliyor http://localhost:${FRONTEND_PORT}"
  xdg-open "http://localhost:${FRONTEND_PORT}" >/dev/null 2>&1 &
else
  echo "  Tarayicinizi su adreste acin: http://localhost:${FRONTEND_PORT}"
fi

echo ""
echo "  ============================================================"
echo "   Calisiyor!"
echo "   Web Arayuzu:     http://localhost:${FRONTEND_PORT}"
echo "   GPU API:    Auto-secili by the app (starts at 8080)"
echo "   Metin API:   Baslats when a GGUF model is yuklendi (port ${LLM_PORT})"
echo "   Ses Tanima:     Managed locally by the app"
echo "   Metinden Sese:        Managed locally by the app"
echo ""
echo "   Tum servisleri durdurmak icin bu pencerede Ctrl+C tuslarina basin."
echo "  ============================================================"
echo ""

# Cleanup on exit
cleanup() {
  echo ""
  echo "  Kapatiliyor..."
  if kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill -TERM "$SERVER_PID" >/dev/null 2>&1 || true
    sleep 1
    kill -KILL "$SERVER_PID" >/dev/null 2>&1 || true
  fi
  echo "  Bitti. Gule gule!"
  exit 0
}
trap cleanup SIGINT SIGTERM

# Keep script alive
wait "$SERVER_PID" || true
cleanup
