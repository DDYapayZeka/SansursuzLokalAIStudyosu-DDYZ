#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
APP_DIR="$ROOT_DIR/app"
TOOLS_DIR="$APP_DIR/tools"
RELEASE="${WHISPER_RELEASE:-v1.9.1}"
PLATFORM="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$PLATFORM" == "Darwin" ]] && [[ "$(sysctl -in hw.optional.arm64 2>/dev/null || true)" == "1" ]]; then
  ARCH="arm64"
fi

download_and_extract() {
  local asset="$1"
  local dest="$2"
  local archive="$TOOLS_DIR/$asset"
  local url="https://github.com/ggml-org/whisper.cpp/releases/download/$RELEASE/$asset"

  if [[ -x "$dest/whisper-cli" ]]; then
    echo "   OK   whisper.cpp konusma arka ucu zaten hazir: $dest"
    return 0
  fi

  mkdir -p "$TOOLS_DIR" "$dest"
  rm -f "$archive" "$archive.part"
  echo "   >>   $asset indiriliyor"
  curl -fSL --progress-bar "$url" -o "$archive.part"
  mv "$archive.part" "$archive"
  if command -v python3 >/dev/null 2>&1; then
    python3 "$SCRIPT_DIR/extract_tar.py" --archive "$archive" --dest "$dest" --strip-components=1
  else
    tar -xzf "$archive" -C "$dest" --strip-components=1
  fi
  rm -f "$archive"
  chmod +x "$dest"/whisper-* "$dest"/main "$dest"/server 2>/dev/null || true

  if [[ ! -x "$dest/whisper-cli" && -x "$dest/main" ]]; then
    cp "$dest/main" "$dest/whisper-cli"
    chmod +x "$dest/whisper-cli"
  fi
  if [[ ! -x "$dest/whisper-server" && -x "$dest/server" ]]; then
    cp "$dest/server" "$dest/whisper-server"
    chmod +x "$dest/whisper-server"
  fi

  if [[ ! -x "$dest/whisper-cli" ]]; then
    echo "   XX   $asset acildiktan sonra whisper-cli bulunamadi" >&2
    return 1
  fi
}

install_macos_whisper_from_homebrew() {
  local cpu_dest="$APP_DIR/speech-backend/mac/cpu"
  local lib_dest="$APP_DIR/speech-backend/mac/lib"
  local brew_bin
  brew_bin="$(command -v brew || true)"
  if [[ -z "$brew_bin" ]]; then
    return 1
  fi

  if ! "$brew_bin" list whisper-cpp >/dev/null 2>&1; then
    echo "   >>   whisper-cpp Homebrew ile kuruluyor..."
    "$brew_bin" install whisper-cpp
  fi

  local whisper_prefix
  whisper_prefix="$("$brew_bin" --prefix whisper-cpp)"
  if [[ ! -x "$whisper_prefix/bin/whisper-cli" ]]; then
    echo "   XX   Homebrew whisper-cpp, $whisper_prefix/bin/whisper-cli konumunda whisper-cli saglamadi" >&2
    return 1
  fi

  mkdir -p "$cpu_dest" "$lib_dest"
  cp "$whisper_prefix/bin/whisper-cli" "$cpu_dest/whisper-cli"
  if [[ -x "$whisper_prefix/bin/whisper-server" ]]; then
    cp "$whisper_prefix/bin/whisper-server" "$cpu_dest/whisper-server"
  fi
  chmod +x "$cpu_dest/whisper-cli" "$cpu_dest/whisper-server" 2>/dev/null || true

  # Homebrew whisper-cli @rpath/libwhisper.1.dylib kullanir. Uygulama baslaticisi
  # onu app/speech-backend/mac/cpu icinden calistirir; ../lib zaten rpath'indedir.
  cp -P "$whisper_prefix"/lib/libwhisper*.dylib "$lib_dest/" 2>/dev/null || true

  if "$cpu_dest/whisper-cli" --help >/dev/null 2>&1; then
    echo "   OK   macOS whisper.cpp arka ucu Homebrew uzerinden kuruldu."
    return 0
  fi

  echo "   XX   whisper-cli kopyalandi ama basariyla calismadi." >&2
  return 1
}

if [[ "$PLATFORM" == "Linux" ]]; then
  mkdir -p "$APP_DIR/speech-backend/linux/cpu" "$APP_DIR/speech-backend/linux/vulkan"
  if [[ ! -x "$APP_DIR/speech-backend/linux/cpu/whisper-cli" && -x "$APP_DIR/speech-backend/linux/whisper-cli" ]]; then
    cp "$APP_DIR/speech-backend/linux"/whisper-* "$APP_DIR/speech-backend/linux/cpu/" 2>/dev/null || true
    cp "$APP_DIR/speech-backend/linux"/main "$APP_DIR/speech-backend/linux/cpu/" 2>/dev/null || true
    cp "$APP_DIR/speech-backend/linux"/server "$APP_DIR/speech-backend/linux/cpu/" 2>/dev/null || true
    chmod +x "$APP_DIR/speech-backend/linux/cpu"/whisper-* "$APP_DIR/speech-backend/linux/cpu"/main "$APP_DIR/speech-backend/linux/cpu"/server 2>/dev/null || true
    echo "   OK   mevcut whisper.cpp CPU arka ucu app/speech-backend/linux/cpu konumuna tasinidi."
  fi
  if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
    download_and_extract "whisper-bin-ubuntu-arm64.tar.gz" "$APP_DIR/speech-backend/linux/cpu"
  else
    download_and_extract "whisper-bin-ubuntu-x64.tar.gz" "$APP_DIR/speech-backend/linux/cpu"
  fi
  echo "   ..   CPU arka ucu yolu: app/speech-backend/linux/cpu"
  echo "   ..   Istege bagli Vulkan GPU arka ucu yolu: app/speech-backend/linux/vulkan"
elif [[ "$PLATFORM" == "Darwin" ]]; then
  mkdir -p "$APP_DIR/speech-backend/mac/cpu" "$APP_DIR/speech-backend/mac/metal"
  if [[ ! -x "$APP_DIR/speech-backend/mac/cpu/whisper-cli" && -x "$APP_DIR/speech-backend/mac/whisper-cli" ]]; then
    cp "$APP_DIR/speech-backend/mac"/whisper-* "$APP_DIR/speech-backend/mac/cpu/" 2>/dev/null || true
    cp "$APP_DIR/speech-backend/mac"/main "$APP_DIR/speech-backend/mac/cpu/" 2>/dev/null || true
    cp "$APP_DIR/speech-backend/mac"/server "$APP_DIR/speech-backend/mac/cpu/" 2>/dev/null || true
    chmod +x "$APP_DIR/speech-backend/mac/cpu"/whisper-* "$APP_DIR/speech-backend/mac/cpu"/main "$APP_DIR/speech-backend/mac/cpu"/server 2>/dev/null || true
    echo "   OK   mevcut whisper.cpp arka ucu app/speech-backend/mac/cpu konumuna tasinidi."
  fi
  if [[ -x "$APP_DIR/speech-backend/mac/cpu/whisper-cli" || -x "$APP_DIR/speech-backend/mac/metal/whisper-cli" ]]; then
    echo "   OK   whisper.cpp macOS konusma arka ucu zaten hazir."
  elif install_macos_whisper_from_homebrew; then
    :
  else
    echo "   !!   macOS whisper.cpp otomatik kurulamadi."
    echo "        Homebrew yuklu degil ve bu uygulama henuz tasinabilir bir macOS whisper.cpp arsivi dagitmiyor."
    echo "        Dagitilabilir bir cozum icin whisper-cli + whisper-server'i app/speech-backend/mac/cpu icine ekleyin"
    echo "        ya da bir Lemonade gomulu konusma arka ucu entegrasyonu ekleyin."
    echo "        Manuel cozum: whisper.cpp'i kurun ve whisper-cli'i app/speech-backend/mac/cpu icine kopyalayin."
  fi
else
  echo "Desteklenmeyen platform: $PLATFORM" >&2
  exit 1
fi
