#!/usr/bin/env bash
#
# Yerel AI Studosu - Kokoro TTS (Linux/macOS) kurulumu
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
APP_DIR="$ROOT_DIR/app"
TOOLS_DIR="$APP_DIR/tools"
PLATFORM="$(uname -s)"

if [[ "$PLATFORM" == "Darwin" ]]; then
  NODE_DIR="$TOOLS_DIR/node-mac"
else
  NODE_DIR="$TOOLS_DIR/node-linux"
fi

NODE_BIN="$NODE_DIR/bin/node"
NPM_BIN="$NODE_DIR/bin/npm"
RUNTIME_DIR="$APP_DIR/tts-runtime"
MODELS_DIR="$APP_DIR/tts-models"
OUTPUTS_DIR="$APP_DIR/tts-outputs"
CACHE_DIR="$APP_DIR/tts-cache"

print_ok() { echo "   OK   $1"; }
print_info() { echo "   >>   $1"; }
print_fail() { echo "   XX   $1"; }

supports_symlinks() {
  local dir="$1"
  local test_target="$dir/.symlink-test-target"
  local test_link="$dir/.symlink-test-link"

  rm -f "$test_target" "$test_link"
  : > "$test_target"
  if ln -s ".symlink-test-target" "$test_link" 2>/dev/null; then
    rm -f "$test_target" "$test_link"
    return 0
  fi

  rm -f "$test_target" "$test_link"
  return 1
}

echo ""
echo "  ============================================================"
echo "   Kokoro ONNX Metinden Sese calistirma ortami kuruluyor"
echo "  ============================================================"
echo ""

mkdir -p "$RUNTIME_DIR" "$MODELS_DIR" "$OUTPUTS_DIR" "$CACHE_DIR"

if [[ ! -x "$NODE_BIN" || ! -x "$NPM_BIN" ]]; then
  print_fail "Tasinabilir Node.js eksik. Once scripts/setup/setup.sh calistirin."
  exit 1
fi

if [[ ! -f "$RUNTIME_DIR/package.json" ]]; then
  cat > "$RUNTIME_DIR/package.json" <<'JSON'
{"private":true,"type":"module","dependencies":{"kokoro-js":"^1.2.1"}}
JSON
fi

cd "$RUNTIME_DIR"
export PATH="$NODE_DIR/bin:$PATH"
print_info "kokoro-js, app/tts-runtime icine kuruluyor..."
if supports_symlinks "$RUNTIME_DIR"; then
  "$NPM_BIN" install --prefer-offline
else
  print_info "Dosya sistemi sembolik baglari desteklemiyor; npm bin baglari olmadan kuruluyor..."
  "$NPM_BIN" install --prefer-offline --no-bin-links
fi

print_ok "Kokoro TTS calistirma ortami hazir."
