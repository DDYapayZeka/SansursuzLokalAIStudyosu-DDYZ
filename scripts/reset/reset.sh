#!/usr/bin/env bash
#
# Sansursuz Lokal AI Studyosu - DD:YZ - Linux/macOS Reset Script
# Resets portable app dependencies/builds while preserving user models and outputs.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
APP_DIR="$ROOT_DIR/app"

echo ""
echo "  ============================================================"
echo "   Sansursuz Lokal AI Studyosu - DD:YZ sifirlaniyor..."
echo "  ============================================================"
echo ""

# Delete portable tools/runtime folder
if [[ -d "$APP_DIR/tools" ]]; then
  echo "   >> Removing portable tools/runtime folder..."
  rm -rf "$APP_DIR/tools"
fi

# Delete backend
if [[ -d "$APP_DIR/backend" ]]; then
  echo "   >> Removing image backend binaries..."
  rm -rf "$APP_DIR/backend"
fi

# Delete llama.cpp backend
if [[ -d "$APP_DIR/llm-backend" ]]; then
  echo "   >> Removing llama.cpp text backend binaries..."
  rm -rf "$APP_DIR/llm-backend"
fi

# Delete whisper.cpp backend
if [[ -d "$APP_DIR/speech-backend" ]]; then
  echo "   >> Removing whisper.cpp speech backend binaries..."
  rm -rf "$APP_DIR/speech-backend"
fi

# Delete Kokoro TTS runtime dependencies
if [[ -d "$APP_DIR/tts-runtime" ]]; then
  echo "   >> Removing Kokoro TTS runtime dependencies..."
  rm -rf "$APP_DIR/tts-runtime"
fi

# Delete dist
if [[ -d "$APP_DIR/dist" ]]; then
  echo "   >> Removing dist/ build folder..."
  rm -rf "$APP_DIR/dist"
fi

# Preserve image models
if [[ -d "$APP_DIR/models" ]]; then
  echo "   >> Preserving image models in app/models."
fi

# Preserve text models
if [[ -d "$APP_DIR/llm-models" ]]; then
  echo "   >> Preserving text models in app/llm-models."
fi

# Preserve speech models
if [[ -d "$APP_DIR/speech-models" ]]; then
  echo "   >> Preserving speech models in app/speech-models."
fi

# Preserve TTS models
if [[ -d "$APP_DIR/tts-models" ]]; then
  echo "   >> Preserving TTS models in app/tts-models."
fi

# Preserve generated image outputs
if [[ -d "$APP_DIR/outputs" ]]; then
  echo "   >> Preserving generated image outputs in app/outputs."
fi

# Preserve chat history
if [[ -d "$APP_DIR/chat-history" ]]; then
  echo "   >> Preserving chat history in app/chat-history."
fi

# Preserve transcriptions
if [[ -d "$APP_DIR/transcriptions" ]]; then
  echo "   >> Preserving speech transcripts in app/transcriptions."
fi

# Preserve TTS outputs/cache
if [[ -d "$APP_DIR/tts-outputs" ]]; then
  echo "   >> Preserving TTS outputs in app/tts-outputs."
fi
if [[ -d "$APP_DIR/tts-cache" ]]; then
  echo "   >> Preserving TTS model cache in app/tts-cache."
fi

# Preserve OpenVINO models
if [[ -d "$APP_DIR/openvino-models" ]]; then
  echo "   >> Preserving OpenVINO models in app/openvino-models."
fi

# Delete all frontend dependency folders, including platform-specific copies
for modules_dir in "$APP_DIR/frontend/node_modules" "$APP_DIR/frontend"/node_modules_*; do
  if [[ -L "$modules_dir" || -d "$modules_dir" ]]; then
    echo "   >> Removing frontend $(basename "$modules_dir")..."
    rm -rf "$modules_dir"
  fi
done

if [[ -f "$APP_DIR/frontend/.active_modules_os" ]]; then
  echo "   >> Removing frontend platform marker..."
  rm -f "$APP_DIR/frontend/.active_modules_os"
fi

# Delete package-lock.json in frontend
if [[ -f "$APP_DIR/frontend/package-lock.json" ]]; then
  echo "   >> Removing frontend package-lock.json..."
  rm -f "$APP_DIR/frontend/package-lock.json"
fi

echo ""
echo "  ============================================================"
echo "   Reset complete. Models, generated images, chat history, transcripts, TTS outputs, TTS cache, and OpenVINO models were preserved."
echo "  ============================================================"
echo ""
read -rp "  Press Enter to close..."
