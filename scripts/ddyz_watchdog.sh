#!/bin/bash
# DD:YZ indirme watchdog - her cagrilda indirmeyi kontrol eder,
# durduysa yeniden baslatir, ilerlemeyi loglar.
# Cron job tarafindan 30 dakikada bir calistirilir (no_agent modunda).

ROOT="/e/SansursuzLokalAIStudyosu-DDYZ"
LOG="/tmp/ddyz_indirme_watchdog.log"
APP="$ROOT/app"
PORT=1420

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"; }

log "=== KONTROL BASLADI ==="

# 1) Sunucu yasiyor mu?
if ! curl -s --max-time 5 "http://localhost:$PORT/api/compatible-models" >/dev/null 2>&1; then
  log "UYARI: sunucu yanit vermiyor, windows.bat baslatiliyor"
  taskkill /F /IM node.exe >/dev/null 2>&1
  sleep 2
  cmd.exe /c "E:\\SansursuzLokalAIStudyosu-DDYZ\\windows.bat" >/dev/null 2>&1 &
  sleep 12
fi

# 2) Hedef dosyalar hazir mi?
sd_done=0; llm_done=0; sp_done=0; tts_done=0
[ -f "$APP/models/v1-5-pruned-emaonly.safetensors" ] && sd_done=1
[ -f "$APP/llm-models/qwen2.5-coder-7b-instruct-q4_k_m.gguf" ] && llm_done=1
[ -f "$APP/speech-models/ggml-base.en.bin" ] && sp_done=1
[ -f "$APP/tts-models/kokoro-onnx-q8.json" ] && tts_done=1
log "Durum: SD1.5=$sd_done Metin(7B)=$llm_done Konusma(base.en)=$sp_done TTS=$tts_done"

# 3) Tum hedefler hazirsa is bitti
if [ "$sd_done" -eq 1 ] && [ "$llm_done" -eq 1 ] && [ "$sp_done" -eq 1 ] && [ "$tts_done" -eq 1 ]; then
  log "TAMAM: tum uyumlu modeller hazir. Watchdog duruyor (elle kapat)."
  echo "TUM MODELLER HAZIR"
  exit 0
fi

# 4) Aktif bir .part var mi ve buyuyor mu?
parts=$(find "$APP/models" "$APP/llm-models" "$APP/speech-models" -name "*.part" 2>/dev/null)
if [ -z "$parts" ]; then
  # Aktif indirme yok ama hedefler de tamam degil => indirme durmus, yeniden baslat
  log "AKTIF .part yok ama modeller eksik => indirme durmus, yeniden baslatiliyor"
  taskkill /F /IM node.exe >/dev/null 2>&1
  sleep 2
  cmd.exe /c "E:\\SansursuzLokalAIStudyosu-DDYZ\\windows.bat" >/dev/null 2>&1 &
  sleep 12
  resp=$(curl -s --max-time 8 -X POST "http://localhost:$PORT/api/download-default-models")
  log "POST yanit: $resp"
else
  # 15sn ara ile 2 olcum, buyuyor mu?
  sz1=0
  for p in $parts; do sz1=$((sz1 + $(stat -c%s "$p" 2>/dev/null || echo 0))); done
  sleep 15
  sz2=0
  for p in $parts; do sz2=$((sz2 + $(stat -c%s "$p" 2>/dev/null || echo 0))); done
  if [ "$sz2" -gt "$sz1" ]; then
    mb=$((sz2/1024/1024))
    log "AKTIF indirme suruyor (~${mb}MB, artis: $(( (sz2-sz1)/1024/1024 ))MB/15sn) - mudahale gerekmiyor"
  else
    log "UYARI: .part var ama buyumuyor (takildi) => yeniden baslatiliyor"
    taskkill /F /IM node.exe >/dev/null 2>&1
    sleep 2
    rm -f $parts
    cmd.exe /c "E:\\SansursuzLokalAIStudyosu-DDYZ\\windows.bat" >/dev/null 2>&1 &
    sleep 12
    resp=$(curl -s --max-time 8 -X POST "http://localhost:$PORT/api/download-default-models")
    log "POST yanit: $resp"
  fi
fi

log "=== KONTROL BITTI ==="
echo "KONTROL TAMAM - log: $LOG"
