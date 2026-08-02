#!/usr/bin/env bash
#
# Yerel AI Studosu - Linux/macOS Kurulum Betigi
# Kendi icinde yeterli: apt/yum/pacman yok, global Node.js kurulumu yok.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
APP_DIR="$ROOT_DIR/app"
FRONTEND_DIR="$APP_DIR/frontend"
TOOLS_DIR="$APP_DIR/tools"
DIST_DIR="$APP_DIR/dist"
PLATFORM="$(uname -s)"
ARCH="$(uname -m)"

if [[ "$PLATFORM" == "Darwin" ]] && [[ "$(sysctl -in hw.optional.arm64 2>/dev/null || true)" == "1" ]]; then
  # Rosetta altinda uname x86_64 rapor eder; arm64 ikililer yine de desteklenir.
  ARCH="arm64"
fi

if [[ "$PLATFORM" == "Darwin" ]]; then
  PLATFORM_LABEL="macOS"
  NODE_DIR="$TOOLS_DIR/node-mac"
  BACKEND_DIR="$APP_DIR/backend/mac"
else
  PLATFORM_LABEL="Linux"
  NODE_DIR="$TOOLS_DIR/node-linux"
  BACKEND_DIR="$APP_DIR/backend/linux"
fi

NODE_BIN="$NODE_DIR/bin/node"
NPM_BIN="$NODE_DIR/bin/npm"

# Dosya sisteminin sembolik baglari destekleyip desteklemedigini kontrol et
USE_SYMLINKS=true
TEST_LINK="$ROOT_DIR/.test_symlink"
rm -f "$TEST_LINK"
if ln -s "test" "$TEST_LINK" 2>/dev/null; then
  rm -f "$TEST_LINK"
else
  USE_SYMLINKS=false
fi

# Surum sabitleri
SD_RELEASE="master-685-19bdfe2"
SD_SHORT_HASH="${SD_RELEASE##*-}"
SD_BASE_URL="https://github.com/leejet/stable-diffusion.cpp/releases/download/$SD_RELEASE"
NODE_VERSION="22.12.0"

if [[ "$PLATFORM" == "Darwin" ]]; then
  if [[ "$ARCH" == "arm64" ]]; then
    NODE_PLATFORM_ARCH="darwin-arm64"
  else
    NODE_PLATFORM_ARCH="darwin-x64"
  fi
  NODE_TARBALL="node-v${NODE_VERSION}-${NODE_PLATFORM_ARCH}.tar.gz"
else
  NODE_PLATFORM_ARCH="linux-x64"
  NODE_TARBALL="node-v${NODE_VERSION}-${NODE_PLATFORM_ARCH}.tar.xz"
fi
NODE_URL="https://nodejs.org/dist/v${NODE_VERSION}/$NODE_TARBALL"

# Bayraklar
MAX_PERF=0
if [[ "${1:-}" == "--max-perf" ]]; then
  MAX_PERF=1
fi

# -- Yardimcilar ---------------------------------------------------------------
print_header() {
  echo ""
  echo "  ============================================================"
  echo "   YEREL AI STUDYOSU      -  $PLATFORM_LABEL Ilk Kurulum"
  echo "   100% Kendi Icinde Yeterli  |  Sistem Kurulumu Gerektirmez"
  echo "  ============================================================"
  echo ""
}

print_step() {
  local n="$1" total="$2" title="$3"
  echo ""
  echo "  [$n/$total] $title"
  echo "  ------------------------------------------------------------"
}

print_ok()   { echo "   OK   $1"; }
print_info() { echo "   >>   $1"; }
print_warn() { echo "   !!   $1"; }
print_fail() { echo "   XX   $1"; }

format_bytes() {
  local b="${1:-0}"
  if command -v bc >/dev/null 2>&1; then
    if (( b > 1073741824 )); then printf "%.2f GB" "$(echo "scale=4; $b / 1073741824" | bc)"; return; fi
    if (( b > 1048576 )); then printf "%.1f MB" "$(echo "scale=4; $b / 1048576" | bc)"; return; fi
    if (( b > 1024 )); then printf "%.0f KB" "$(echo "scale=4; $b / 1024" | bc)"; return; fi
  else
    if (( b > 1073741824 )); then printf "%.2f GB" "$(awk "BEGIN {printf \"%.2f\", $b/1073741824}")"; return; fi
    if (( b > 1048576 )); then printf "%.1f MB" "$(awk "BEGIN {printf \"%.1f\", $b/1048576}")"; return; fi
    if (( b > 1024 )); then printf "%.0f KB" "$(awk "BEGIN {printf \"%.0f\", $b/1024}")"; return; fi
  fi
  printf "%s B" "$b"
}

# Ilerleme cubuguyla zengin indirme
download_file() {
  local url="$1" dest="$2" label="$3"
  print_info "Indiriliyor: $label"
  echo ""

  local tmp_dest="${dest}.part"
  rm -f "$tmp_dest"

  curl -fSL --progress-bar "$url" -o "$tmp_dest" || {
    print_fail "Indirme basarisiz: $url"
    rm -f "$tmp_dest"
    return 1
  }

  mv "$tmp_dest" "$dest"
  echo ""
  local fsize
  fsize="$(stat -c%s "$dest" 2>/dev/null || stat -f%z "$dest" 2>/dev/null || echo 0)"
  print_ok "Indirildi $(format_bytes "$fsize")"
}

# Python zipfile (tercih edilen), unzip veya Node.js adm-zip ile ZIP acma
extract_zip() {
  local zip_path="$1" dest="$2" label="$3"
  print_info "Aciliyor: $label"
  mkdir -p "$dest"

  # Python zipfile tercih edilir (python3 disinda host bagimliligi yoktur)
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
import zipfile, sys, os
with zipfile.ZipFile(sys.argv[1], 'r') as z:
    for member in z.namelist():
        z.extract(member, sys.argv[2])
" "$zip_path" "$dest" && return 0
  fi

  if command -v unzip >/dev/null 2>&1; then
    unzip -o -q "$zip_path" -d "$dest" && return 0
  fi

  if command -v python >/dev/null 2>&1; then
    python -c "import zipfile, sys; zipfile.ZipFile(sys.argv[1], 'r').extractall(sys.argv[2])" "$zip_path" "$dest" && return 0
  fi

  print_fail "Kullanilabilir ZIP acicisi yok (python3, unzip, python denendi)."
  return 1
}

# tar.xz acma
extract_tarxz() {
  local tar_path="$1" dest="$2" label="$3"
  print_info "Aciliyor: $label"
  mkdir -p "$dest"
  if [ "$USE_SYMLINKS" = false ]; then
    # Sembolik baglari desteklemeyen dosya sistemlerinde tar, sembolik bag olusturmaya
    # calisirken basarisiz olur (ornegin npm/npx/corepack icin Node.js bin/ dizininde).
    # Devam etmesine izin veriyoruz ama anahtar dosyalari dogruluyoruz.
    local tar_exit=0
    tar -xf "$tar_path" -C "$dest" || tar_exit=$?
    if [[ $tar_exit -ne 0 ]]; then
      # node ikilisinin acildigini kontrol et
      local check_file
      check_file="$(find "$dest" -type f -name "node" | head -n 1)"
      if [[ -n "$check_file" ]]; then
        print_warn "tar, bu dosya sisteminde sembolik bag hatalari nedeniyle cikis $tar_exit dondurdu, ancak bin/node basariyla acildi."
      else
        print_fail "tar acma islemi $tar_exit koduyla basarisiz oldu (bin/node bulunamadi)"
        exit $tar_exit
      fi
    fi
  else
    tar -xf "$tar_path" -C "$dest"
  fi
  print_ok "$label acildi"
}

detect_gpu_vendor() {
  local vendor=""
  if [[ -d /sys/bus/pci/devices ]]; then
    for vfile in /sys/bus/pci/devices/*/vendor; do
      if [[ -f "$vfile" ]]; then
        local vid
        vid="$(cat "$vfile" 2>/dev/null || true)"
        case "$vid" in
          "0x10de") vendor="nvidia" ;;
          "0x1002") vendor="amd" ;;
          "0x8086") [[ -z "$vendor" ]] && vendor="intel" ;;
        esac
      fi
    done
  fi
  echo "$vendor"
}

# Resmi Linux ikilileri Ubuntu 24.04 uzerine kuruludur ve glibc 2.38+
# arti GLIBCXX_3.4.32+ baglanti gerektirir. Arka ucun baslatilamayacagi eski
# dagitimlarda kurulumun basariya ulasmis gibi gozukmesini engellemek icin erken dur.
version_at_least() {
  local current="$1" required="$2"
  [[ "$(printf '%s\n' "$required" "$current" | sort -V | head -n1)" == "$required" ]]
}

detect_glibcxx_version() {
  local libstdcpp=""
  if command -v ldconfig >/dev/null 2>&1; then
    libstdcpp="$(ldconfig -p 2>/dev/null | awk '/libstdc\+\+\.so\.6/{print $NF; exit}')"
  fi
  if [[ -z "$libstdcpp" ]]; then
    for candidate in /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib64/libstdc++.so.6 /lib/x86_64-linux-gnu/libstdc++.so.6; do
      if [[ -f "$candidate" ]]; then
        libstdcpp="$candidate"
        break
      fi
    done
  fi
  if [[ -n "$libstdcpp" && -f "$libstdcpp" ]] && command -v strings >/dev/null 2>&1; then
    strings "$libstdcpp" 2>/dev/null | grep -oE 'GLIBCXX_[0-9]+\.[0-9]+\.[0-9]+' | sed 's/GLIBCXX_//' | sort -V | tail -n1
  fi
}

check_linux_runtime_abi() {
  local required_glibc="2.38"
  local required_glibcxx="3.4.32"
  local current_glibc=""
  local current_glibcxx=""
  local unsupported=0

  if command -v ldd >/dev/null 2>&1; then
    current_glibc="$(ldd --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -n1 || true)"
  fi
  current_glibcxx="$(detect_glibcxx_version || true)"

  if [[ -z "$current_glibc" ]]; then
    print_warn "glibc surumu algilanamadi. Onceden derlenmis Linux arka uclari glibc $required_glibc+ (Ubuntu 24.04) gerektirir."
  elif ! version_at_least "$current_glibc" "$required_glibc"; then
    print_fail "Algilanan glibc $current_glibc. Onceden derlenmis Linux arka uclari glibc $required_glibc+ (Ubuntu 24.04 veya daha yeni) gerektirir."
    unsupported=1
  fi

  if [[ -z "$current_glibcxx" ]]; then
    print_warn "GLIBCXX surumu algilanamadi. Onceden derlenmis Linux arka uclari GLIBCXX_$required_glibcxx+ gerektirir."
  elif ! version_at_least "$current_glibcxx" "$required_glibcxx"; then
    print_fail "Algilanan GLIBCXX_$current_glibcxx. Onceden derlenmis Linux arka uclari GLIBCXX_$required_glibcxx+ gerektirir."
    unsupported=1
  fi

  if [[ $unsupported -ne 0 ]]; then
    print_info "CyberRealistic ve diger gecerli modeller, arka uc ikilisi baslamadigi icin bu isletim sisteminde yukleme oncesi basarisiz olur."
    print_info "Cozum: Ubuntu 24.04+, Fedora 40+ veya baska bir glibc 2.38+ dagitimi kullanin ya da stable-diffusion.cpp'i bu makinede kaynaktan derleyin."
    if [[ "${UAIS_ALLOW_UNSUPPORTED_LINUX:-0}" == "1" ]]; then
      print_warn "UAIS_ALLOW_UNSUPPORTED_LINUX=1 ayarli oldugu icin yine de devam ediliyor."
      return 0
    fi
    return 1
  fi

  print_ok "Linux calisma ABI hazir: glibc $current_glibc, GLIBCXX_$current_glibcxx"
}

has_linux_shared_library() {
  local library="$1"
  if command -v ldconfig >/dev/null 2>&1 && grep -Fq "$library" < <(ldconfig -p 2>/dev/null); then
    return 0
  fi
  [[ -n "$(find /lib /lib64 /usr/lib /usr/lib64 -name "$library" -print -quit 2>/dev/null)" ]]
}

check_linux_runtime_dependencies() {
  if ! has_linux_shared_library "libgomp.so.1"; then
    print_fail "Gerekli OpenMP calisma ortami (libgomp.so.1) eksik."
    print_info "Ubuntu/Debian: sudo apt-get update && sudo apt-get install -y libgomp1"
    print_info "Fedora: sudo dnf install libgomp"
    return 1
  fi
  print_ok "Linux OpenMP calisma ortami hazir: libgomp.so.1"
}

linux_backend_is_healthy() {
  local binary="$1"
  local backend_dir="$2"
  local reject_pattern="${3:-}"
  [[ -x "$binary" ]] || return 1
  command -v ldd >/dev/null 2>&1 || return 0

  local output
  output="$(LD_LIBRARY_PATH="$backend_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" ldd "$binary" 2>&1 || true)"
  if grep -q "not found" <<<"$output"; then
    return 1
  fi
  if [[ -n "$reject_pattern" ]] && grep -Eqi "$reject_pattern" <<<"$output"; then
    return 1
  fi
  return 0
}

copy_binaries_from_extracted() {
  local extracted_dir="$1" dest_dir="$2" main_name="$3" server_name="$4"

  while IFS= read -r -d '' f; do
    local base
    base="$(basename "$f")"
    case "$base" in
      sd|sd-cli) cp "$f" "$dest_dir/$main_name" ;;
      sd-server) cp "$f" "$dest_dir/$server_name" ;;
    esac
  done < <(find "$extracted_dir" -type f \( -name "sd" -o -name "sd-cli" -o -name "sd-server" \) -print0 2>/dev/null)

  # .so dosyalarini kopyala
  find "$extracted_dir" -type f -name "*.so" -exec cp {} "$dest_dir/" \; 2>/dev/null || true
}

copy_macos_backend_from_extracted() {
  local extracted_dir="$1" dest_dir="$2"
  local target="$dest_dir/sd"
  local server_bin=""
  local cli_bin=""

  server_bin="$(find "$extracted_dir" -type f -name "sd-server" | head -n 1)"
  cli_bin="$(find "$extracted_dir" -type f \( -name "sd" -o -name "sd-cli" \) | head -n 1)"

  if [[ -n "$server_bin" ]]; then
    cp "$server_bin" "$target"
  elif [[ -n "$cli_bin" ]]; then
    cp "$cli_bin" "$target"
  else
    print_fail "macOS arka uc arsivinde sd-server, sd veya sd-cli ikilisi bulunamadi."
    return 1
  fi

  find "$extracted_dir" -type f \( -name "*.dylib" -o -name "*.metallib" \) -exec cp {} "$dest_dir/" \; 2>/dev/null || true
  chmod +x "$target" 2>/dev/null || true
}

# ===========================================================================
print_header

if [[ "$PLATFORM" == "Linux" ]]; then
  if ! check_linux_runtime_abi; then
    print_fail "Linux kurulumu, uyumsuz arka uc ikilileri indirilmeden durduruldu."
    exit 1
  fi
  if ! check_linux_runtime_dependencies; then
    print_fail "Linux kurulumu, eksik calisma zamani kutuphaneleriyle arka uclar kurulmadan durduruldu."
    exit 1
  fi
fi

TOTAL_STEPS=7

# -- Adim 1: Tasinabilir Node.js -----------------------------------------------
print_step 1 $TOTAL_STEPS "Tasinabilir Node.js ayarlaniyor ($NODE_DIR/)"

EXPECTED_NODE_ARCH="${NODE_PLATFORM_ARCH##*-}"
INSTALLED_NODE_ARCH=""
if [[ -x "$NODE_BIN" ]]; then
  INSTALLED_NODE_ARCH="$($NODE_BIN -p "process.arch" 2>/dev/null || true)"
fi

if [[ -x "$NODE_BIN" && -x "$NPM_BIN" && "$INSTALLED_NODE_ARCH" == "$EXPECTED_NODE_ARCH" ]]; then
  VERSION=$("$NODE_BIN" --version)
  print_ok "Tasinabilir Node.js zaten hazir: $VERSION"
else
  if [[ -n "$INSTALLED_NODE_ARCH" && "$INSTALLED_NODE_ARCH" != "$EXPECTED_NODE_ARCH" ]]; then
    print_warn "Tasinabilir Node.js $INSTALLED_NODE_ARCH, bu donanim icin $EXPECTED_NODE_ARCH ile degistiriliyor."
    rm -rf "$NODE_DIR"
  fi
  mkdir -p "$TOOLS_DIR"
  NODE_TAR_PATH="$TOOLS_DIR/$NODE_TARBALL"

  download_file "$NODE_URL" "$NODE_TAR_PATH" "Node.js v${NODE_VERSION} LTS (Tasinabilir arsiv)"
  extract_tarxz "$NODE_TAR_PATH" "$TOOLS_DIR" "Node.js"
  rm -f "$NODE_TAR_PATH"

  EXTRACTED_DIR="$(find "$TOOLS_DIR" -maxdepth 1 -type d -name "node-v*-${NODE_PLATFORM_ARCH}" | head -n 1)"
  if [[ -d "$EXTRACTED_DIR" ]]; then
    rm -rf "$NODE_DIR"
    mv "$EXTRACTED_DIR" "$NODE_DIR"
  fi

  if [ "$USE_SYMLINKS" = false ]; then
    print_info "Dosya sistemi sembolik baglari desteklemiyor. npm, npx ve corepack icin kabuk sarmalayicilari olusturuluyor..."
    rm -f "$NODE_DIR/bin/npm" "$NODE_DIR/bin/npx" "$NODE_DIR/bin/corepack"

    cat << 'EOF' > "$NODE_DIR/bin/npm"
#!/bin/sh
basedir=$(dirname "$0")
exec "$basedir/node" "$basedir/../lib/node_modules/npm/bin/npm-cli.js" "$@"
EOF
    chmod +x "$NODE_DIR/bin/npm"

    cat << 'EOF' > "$NODE_DIR/bin/npx"
#!/bin/sh
basedir=$(dirname "$0")
exec "$basedir/node" "$basedir/../lib/node_modules/npm/bin/npx-cli.js" "$@"
EOF
    chmod +x "$NODE_DIR/bin/npx"

    cat << 'EOF' > "$NODE_DIR/bin/corepack"
#!/bin/sh
basedir=$(dirname "$0")
exec "$basedir/node" "$basedir/../lib/node_modules/corepack/dist/corepack.js" "$@"
EOF
    chmod +x "$NODE_DIR/bin/corepack"

    print_ok "Kabuk sarmalayicilari olusturuldu."
  fi

  if [[ ! -x "$NODE_BIN" || ! -x "$NPM_BIN" ]]; then
    print_fail "Tasinabilir Node.js kurulumu eksik."
    exit 1
  fi

  VERSION=$("$NODE_BIN" --version)
  print_ok "Tasinabilir Node.js hazir: $VERSION"
fi

# -- Adim 2: stable-diffusion.cpp Arka Uclari ----------------------------------
mkdir -p "$BACKEND_DIR"

if [[ "$PLATFORM" == "Darwin" ]]; then
  print_step 2 $TOTAL_STEPS "stable-diffusion.cpp Metal arka ucu ayarlaniyor (app/backend/mac/)"
  if [[ "$ARCH" != "arm64" ]]; then
    print_fail "Resmi macOS arka uc ikilisi yalnizca Apple Silicon'dir (arm64)."
    print_info "macOS Intel donanimi tamamen desteklenmiyor ve test edilmedi."
    exit 1
  fi

  MAC_BACKEND="$BACKEND_DIR/sd"
  if [[ -x "$MAC_BACKEND" ]]; then
    print_ok "macOS Metal arka ucu zaten hazir."
  else
    MAC_ZIP="$TOOLS_DIR/sd-mac-metal.zip"
    download_file "$SD_BASE_URL/sd-master-${SD_SHORT_HASH}-bin-Darwin-macOS-15.7.7-arm64.zip" "$MAC_ZIP" "stable-diffusion.cpp Metal Arka Ucu (macOS arm64)"
    extract_zip "$MAC_ZIP" "$BACKEND_DIR/extracted" "macOS Metal Arka Ucu"
    rm -f "$MAC_ZIP"
    copy_macos_backend_from_extracted "$BACKEND_DIR/extracted" "$BACKEND_DIR"
    rm -rf "$BACKEND_DIR/extracted"
    print_ok "macOS Metal arka ucu kuruldu."
  fi

  # CoreML NPU ortam kurulumu (yalnizca macOS Apple Silicon)
  print_info "Apple Silicon ANE (NPU) icin CoreML Python sanal ortami ayarlaniyor..."
  VENV_DIR="$BACKEND_DIR/coreml_venv"
  PYTHON_BIN="$VENV_DIR/bin/python"

  if [[ ! -x "$PYTHON_BIN" ]]; then
    print_info "CoreML icin Python sanal ortami olusturuluyor: $VENV_DIR..."
    if ! python3 -m venv "$VENV_DIR"; then
      print_warn "CoreML icin sanal ortam olusturulamadi. CoreML NPU modu kullanilamayacak."
    fi
  fi

  if [[ -x "$PYTHON_BIN" ]]; then
    print_info "CoreML bagimliliklari kuruluyor (birkac dakika surebilir)..."
    if "$PYTHON_BIN" -m pip install --upgrade pip >/dev/null 2>&1 && \
       "$PYTHON_BIN" -m pip install numpy coremltools diffusers transformers huggingface-hub pillow >/dev/null 2>&1 && \
       "$PYTHON_BIN" -m pip install "git+https://github.com/apple/ml-stable-diffusion.git" >/dev/null 2>&1; then
      print_ok "CoreML ANE (NPU) ortami hazir."
    else
      print_warn "CoreML bagimliliklari kurulumu basarisiz. CoreML NPU modu kullanilamayacak."
    fi
  fi
else
  VENDOR="$(detect_gpu_vendor)"
  print_step 2 $TOTAL_STEPS "GPU ureticisi algilaniyor: ${VENDOR:-yok}"

# CPU arka ucu (her zaman)
CPU_BACKEND_DIR="$BACKEND_DIR/cpu"
if ! linux_backend_is_healthy "$CPU_BACKEND_DIR/sd-server-cpu" "$CPU_BACKEND_DIR"; then
  mkdir -p "$CPU_BACKEND_DIR"
  rm -rf "$CPU_BACKEND_DIR/extracted"
  rm -f "$CPU_BACKEND_DIR"/sd-cpu "$CPU_BACKEND_DIR"/sd-server-cpu "$CPU_BACKEND_DIR"/*.so
  CPU_ZIP="$TOOLS_DIR/sd-cpu.zip"
  download_file "$SD_BASE_URL/sd-master-${SD_SHORT_HASH}-bin-Linux-Ubuntu-24.04-x86_64.zip" "$CPU_ZIP" "stable-diffusion.cpp CPU Arka Ucu (Linux x86_64)"
  extract_zip "$CPU_ZIP" "$CPU_BACKEND_DIR/extracted" "CPU Arka Ucu"
  rm -f "$CPU_ZIP"
  copy_binaries_from_extracted "$CPU_BACKEND_DIR/extracted" "$CPU_BACKEND_DIR" "sd-cpu" "sd-server-cpu"
  rm -rf "$CPU_BACKEND_DIR/extracted"
  print_ok "CPU arka ucu kuruldu."
else
  print_ok "CPU arka ucu zaten hazir."
fi
chmod +x "$CPU_BACKEND_DIR/sd-cpu" "$CPU_BACKEND_DIR/sd-server-cpu" 2>/dev/null || true

# Vulkan arka ucu (her zaman - cok ureticili GPU yedegi)
VULKAN_BACKEND_DIR="$BACKEND_DIR/vulkan"
if ! has_linux_shared_library "libvulkan.so.1"; then
  print_warn "Vulkan calisma kutuphanesi libvulkan.so.1 eksik; CPU arka ucu kullanilabilir kalacak."
  print_info "Ubuntu/Debian: sudo apt-get install -y libvulkan1 mesa-vulkan-drivers"
  print_info "Fedora: sudo dnf install vulkan-loader mesa-vulkan-drivers"
elif ! linux_backend_is_healthy "$VULKAN_BACKEND_DIR/sd-server-vulkan" "$VULKAN_BACKEND_DIR" "hipblas|rocblas|amdhip"; then
  mkdir -p "$VULKAN_BACKEND_DIR"
  rm -rf "$VULKAN_BACKEND_DIR/extracted"
  rm -f "$VULKAN_BACKEND_DIR"/sd-vulkan "$VULKAN_BACKEND_DIR"/sd-server-vulkan "$VULKAN_BACKEND_DIR"/*.so
  VULKAN_ZIP="$TOOLS_DIR/sd-vulkan.zip"
  download_file "$SD_BASE_URL/sd-master-${SD_SHORT_HASH}-bin-Linux-Ubuntu-24.04-x86_64-vulkan.zip" "$VULKAN_ZIP" "stable-diffusion.cpp Vulkan Arka Ucu (Linux x86_64)"
  extract_zip "$VULKAN_ZIP" "$VULKAN_BACKEND_DIR/extracted" "Vulkan Arka Ucu"
  rm -f "$VULKAN_ZIP"
  copy_binaries_from_extracted "$VULKAN_BACKEND_DIR/extracted" "$VULKAN_BACKEND_DIR" "sd-vulkan" "sd-server-vulkan"
  rm -rf "$VULKAN_BACKEND_DIR/extracted"
  print_ok "Vulkan arka ucu kuruldu."
else
  print_ok "Vulkan arka ucu zaten hazir."
fi
chmod +x "$VULKAN_BACKEND_DIR/sd-vulkan" "$VULKAN_BACKEND_DIR/sd-server-vulkan" 2>/dev/null || true

# ROCm arka ucu (istege bagli --max-perf ya da otomatik algilanan AMD)
ROCM_BACKEND_DIR="$BACKEND_DIR/rocm"
if [[ $MAX_PERF -eq 1 ]] && [[ "$VENDOR" == "amd" || "$VENDOR" == "" ]]; then
  if [[ ! -f "$ROCM_BACKEND_DIR/sd-rocm" || ! -f "$ROCM_BACKEND_DIR/sd-server-rocm" ]]; then
    mkdir -p "$ROCM_BACKEND_DIR"
    ROCM_ZIP="$TOOLS_DIR/sd-rocm.zip"
    print_warn "ROCm arka ucu ~1.2 GB. Bu biraz zaman alabilir..."
    download_file "$SD_BASE_URL/sd-master-${SD_SHORT_HASH}-bin-Linux-Ubuntu-24.04-x86_64-rocm-7.13.0.zip" "$ROCM_ZIP" "stable-diffusion.cpp ROCm Arka Ucu (Linux x86_64)"
    extract_zip "$ROCM_ZIP" "$ROCM_BACKEND_DIR/extracted" "ROCm Arka Ucu"
    rm -f "$ROCM_ZIP"
    copy_binaries_from_extracted "$ROCM_BACKEND_DIR/extracted" "$ROCM_BACKEND_DIR" "sd-rocm" "sd-server-rocm"
    rm -rf "$ROCM_BACKEND_DIR/extracted"
    print_ok "ROCm arka ucu kuruldu."
  else
    print_ok "ROCm arka ucu zaten hazir."
  fi
  chmod +x "$ROCM_BACKEND_DIR/sd-rocm" "$ROCM_BACKEND_DIR/sd-server-rocm" 2>/dev/null || true
fi

# CUDA arka ucu (Linux): kullaniciya sor, once onceden derlenmis ikili indir,
# yedek olarak kaynaktan derle.
CUDA_BACKEND_DIR="$BACKEND_DIR/cuda"
if [[ "$VENDOR" == "nvidia" ]]; then
  if [[ ! -f "$CUDA_BACKEND_DIR/sd-cuda" || ! -f "$CUDA_BACKEND_DIR/sd-server-cuda" ]]; then
    echo ""
    echo "  ============================================================"
    echo "   NVIDIA GPU Algilandi"
    echo "  ============================================================"
    echo "   En iyi performans icin CUDA arka ucunu kullanabilirsiniz."
    echo "   Bunun ayarlanmasi onceden derlenmis bir ikili indirebilir veya"
    echo "   kaynaktan derleyebilir (bu 10-15 dakika surer)."
    echo ""
    echo "   Alternatif olarak, zaten kurulu olan ve hemen calisan Vulkan"
    echo "   arka ucunu kullanabilirsiniz (GTX kartlari icin onerilir)."
    echo "  ============================================================"
    echo ""

    CHOOSE_CUDA="n"
    if [[ -t 0 ]]; then
      read -t 30 -rp "   CUDA kurulumuna devam etmek istiyor musunuz? [e/H]: " CHOOSE_CUDA || CHOOSE_CUDA="n"
    else
      print_info "Etkilesimli olmayan ortam algilandi; varsayilan olarak Vulkan kullaniliyor."
    fi

    if [[ "$CHOOSE_CUDA" =~ ^[Ee]$ ]]; then
      TRY_DOWNLOAD=1
      PREBUILT_URL="https://github.com/leaxer-ai/leaxer-stable-diffusion/releases/download/v0.1.0/sd-server-x86_64-unknown-linux-gnu-cuda"
      PREBUILT_CLI_URL="https://github.com/leaxer-ai/leaxer-stable-diffusion/releases/download/v0.1.0/sd-x86_64-unknown-linux-gnu-cuda"

      mkdir -p "$CUDA_BACKEND_DIR"

      print_info "Onceden derlenmis CUDA ikilisi indirilmeye calisiliyor..."
      if download_file "$PREBUILT_URL" "$CUDA_BACKEND_DIR/sd-server-cuda" "Onceden Derlenmis Linux CUDA Sunucusu" && \
         download_file "$PREBUILT_CLI_URL" "$CUDA_BACKEND_DIR/sd-cuda" "Onceden Derlenmis Linux CUDA CLI"; then

        chmod +x "$CUDA_BACKEND_DIR/sd-server-cuda" "$CUDA_BACKEND_DIR/sd-cuda" 2>/dev/null || true

        print_info "Indirilen onceden derlenmis CUDA ikilisi test ediliyor..."
        if "$CUDA_BACKEND_DIR/sd-server-cuda" --help >/dev/null 2>&1; then
          print_ok "Onceden derlenmis CUDA ikilisi dogrulandi ve calisiyor! Derleme atlaniyor."
          TRY_DOWNLOAD=0
        else
          print_warn "Onceden derlenmis CUDA ikilisi dogrulama testini gecmedi (eksik kutuphane veya uyumsuzluk)."
          rm -f "$CUDA_BACKEND_DIR/sd-server-cuda" "$CUDA_BACKEND_DIR/sd-cuda"
        fi
      else
        print_warn "Onceden derlenmis CUDA ikilisi indirilemedi."
        rm -f "$CUDA_BACKEND_DIR/sd-server-cuda" "$CUDA_BACKEND_DIR/sd-cuda"
      fi

      if [[ $TRY_DOWNLOAD -eq 1 ]]; then
        if command -v nvcc >/dev/null 2>&1 && command -v cmake >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
          print_info "NVIDIA GPU ve CUDA derleme araclari (nvcc, cmake, git) algilandi."
          print_info "CUDA arka ucu kaynaktan derleniyor..."

          BUILD_DIR="$TOOLS_DIR/build-sd"
          JOBS="$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)"

          if [[ ! -d "$BUILD_DIR" ]]; then
            print_info "stable-diffusion.cpp klonlaniyor..."
            git clone https://github.com/leejet/stable-diffusion.cpp.git "$BUILD_DIR"
          fi

          PUSHED_DIR="$(pwd)"
          cd "$BUILD_DIR"

          print_info "Sabitlenmis etiket $SD_RELEASE kontrol ediliyor..."
          git fetch origin
          git checkout -f "$SD_RELEASE"
          git submodule update --init --recursive

          rm -rf build-cuda && mkdir build-cuda && cd build-cuda

          print_info "CUDA arka ucu icin cmake calistiriliyor..."
          if cmake .. -DSD_CUDA=ON -DSD_BUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release -DGGML_CUDA_FORCE_MMQ=ON && \
             cmake --build . --config Release -j"$JOBS"; then

            mkdir -p "$CUDA_BACKEND_DIR"
            if [[ -f bin/sd-server ]]; then
              cp bin/sd-server "$CUDA_BACKEND_DIR/sd-cuda"
              cp bin/sd-server "$CUDA_BACKEND_DIR/sd-server-cuda"
            else
              print_fail "CUDA derlemesi basariyla tamamlandi ama bin/sd-server bulunamadi."
              cd "$PUSHED_DIR"
              exit 1
            fi

            if [[ -f bin/sd ]]; then
              cp bin/sd "$CUDA_BACKEND_DIR/sd-cli-cuda"
            elif [[ -f bin/sd-cli ]]; then
              cp bin/sd-cli "$CUDA_BACKEND_DIR/sd-cli-cuda"
            fi

            SO_PATH_CUDA=$(find . -name "libstable-diffusion.so" | head -n 1)
            if [[ -n "$SO_PATH_CUDA" ]]; then
              cp "$SO_PATH_CUDA" "$CUDA_BACKEND_DIR/"
            fi

            chmod +x "$CUDA_BACKEND_DIR/sd-cuda" "$CUDA_BACKEND_DIR/sd-server-cuda" 2>/dev/null || true
            if [[ -f "$CUDA_BACKEND_DIR/sd-cli-cuda" ]]; then
              chmod +x "$CUDA_BACKEND_DIR/sd-cli-cuda" 2>/dev/null || true
            fi
            print_ok "CUDA arka ucu kaynaktan derlenip kuruldu."
          else
            print_warn "CUDA arka ucu kaynaktan derleme basarisiz. Vulkan'a geri donuluyor."
          fi
          cd "$PUSHED_DIR"
        else
          print_warn "CUDA derleme araclari (nvcc, cmake ve/veya git) eksik."
          print_info "CUDA arka ucunu derlemek icin NVIDIA CUDA Toolkit, cmake ve git kurun."
          print_info "Vulkan'a geri donuluyor."
        fi
      fi
    else
      print_info "CUDA kurulumu reddedildi. Bunun yerine Vulkan GPU arka ucu kullaniliyor."
    fi
  else
    print_ok "CUDA arka ucu zaten hazir."
  fi
fi
fi

# -- Adim 3: npm install ------------------------------------------------------
print_step 3 $TOTAL_STEPS "llama.cpp metin arka ucu ayarlaniyor"
bash "$SCRIPT_DIR/setup-llama.sh"

print_step 4 $TOTAL_STEPS "whisper.cpp konusma arka ucu ayarlaniyor"
bash "$SCRIPT_DIR/setup-whisper.sh"

print_step 5 $TOTAL_STEPS "Kokoro ONNX metinden sese calistirma ortami ayarlaniyor"
bash "$SCRIPT_DIR/setup-tts.sh"

print_step 6 $TOTAL_STEPS "On yuze bagimliliklari kuruluyor (app/frontend/)"

if [[ ! -x "$NPM_BIN" ]]; then
  print_fail "Tasinabilir npm surada bulunamadi: $NPM_BIN"
  exit 1
fi

# Dogru isletim sistemine ozgu node_modules klasorunun sembolik bagli veya
# takas edilmis oldugundan emin ol (cakis malarini onlemek icin)
FRONTEND_NODE_MODULES="$FRONTEND_DIR/node_modules"
ACTIVE_OS_FILE="$FRONTEND_DIR/.active_modules_os"

if [[ "$PLATFORM" == "Darwin" ]]; then
  OS_NODE_MODULES="$FRONTEND_DIR/node_modules_mac"
  OS_LABEL="node_modules_mac"
  CURRENT_OS="mac"
else
  OS_NODE_MODULES="$FRONTEND_DIR/node_modules_linux"
  OS_LABEL="node_modules_linux"
  CURRENT_OS="linux"
fi

# Dosya sisteminin sembolik baglari destekleyip desteklemedigini kontrol et
USE_SYMLINKS=true
TEST_LINK="$FRONTEND_DIR/.test_symlink"
rm -f "$TEST_LINK"
if ln -s "$OS_LABEL" "$TEST_LINK" 2>/dev/null; then
  rm -f "$TEST_LINK"
else
  USE_SYMLINKS=false
fi

if [ "$USE_SYMLINKS" = true ]; then
  if [[ -d "$FRONTEND_NODE_MODULES" && ! -L "$FRONTEND_NODE_MODULES" ]]; then
    print_info "Mevcut node_modules $OS_LABEL konumuna tasiniliyor..."
    if [[ -d "$OS_NODE_MODULES" ]]; then
      rm -rf "$FRONTEND_NODE_MODULES"
    else
      mv "$FRONTEND_NODE_MODULES" "$OS_NODE_MODULES"
    fi
  fi
  rm -rf "$FRONTEND_NODE_MODULES"
  mkdir -p "$OS_NODE_MODULES"
  ln -sf "$OS_LABEL" "$FRONTEND_NODE_MODULES"
else
  # Yedek: Dosya sistemi sembolik baglari desteklemiyor (orn. FAT32/exFAT)
  print_info "Dosya sistemi sembolik baglari desteklemiyor. Dizin takas yedegi kullaniliyor..."

  if [[ -L "$FRONTEND_NODE_MODULES" || -f "$FRONTEND_NODE_MODULES" ]]; then
    rm -rf "$FRONTEND_NODE_MODULES"
  fi

  PREV_OS=""
  if [[ -f "$ACTIVE_OS_FILE" ]]; then
    PREV_OS=$(cat "$ACTIVE_OS_FILE")
  fi

  if [[ -d "$FRONTEND_NODE_MODULES" && "$PREV_OS" != "$CURRENT_OS" ]]; then
    if [[ -n "$PREV_OS" ]]; then
      print_info "node_modules node_modules_$PREV_OS konumuna takas ediliyor..."
      rm -rf "$FRONTEND_DIR/node_modules_$PREV_OS"
      mv "$FRONTEND_NODE_MODULES" "$FRONTEND_DIR/node_modules_$PREV_OS"
    else
      print_info "node_modules node_modules_windows olarak kaydediliyor..."
      rm -rf "$FRONTEND_DIR/node_modules_windows"
      mv "$FRONTEND_NODE_MODULES" "$FRONTEND_DIR/node_modules_windows"
    fi
  fi

  if [[ -d "$OS_NODE_MODULES" && ! -d "$FRONTEND_NODE_MODULES" ]]; then
    print_info "$OS_LABEL takas ediliyor..."
    mv "$OS_NODE_MODULES" "$FRONTEND_NODE_MODULES"
  elif [[ ! -d "$FRONTEND_NODE_MODULES" ]]; then
    mkdir -p "$FRONTEND_NODE_MODULES"
  fi

  echo "$CURRENT_OS" > "$ACTIVE_OS_FILE"
fi

cd "$FRONTEND_DIR"
export PATH="$NODE_DIR/bin:$PATH"

if [ "$USE_SYMLINKS" = false ]; then
  if "$NPM_BIN" install --prefer-offline --no-bin-links; then
    print_ok "Bagimliliklar kuruldu!"
  else
    print_fail "npm install basarisiz oldu."
    exit 1
  fi
else
  if "$NPM_BIN" install --prefer-offline; then
    print_ok "Bagimliliklar kuruldu!"
  else
    print_fail "npm install basarisiz oldu."
    exit 1
  fi
fi

# -- Adim 4: On yuzu derle ---------------------------------------------------
print_step 7 $TOTAL_STEPS "On yuz derleniyor -> app/dist/"

if [ "$USE_SYMLINKS" = false ]; then
  # Sembolik baglar devre disiysa, vite'i yerel node ikilisiyle dogrudan calistir.
  if "$NODE_BIN" node_modules/vite/bin/vite.js build; then
    print_ok "On yuz derlendi!"
  else
    print_fail "On yuz derlemesi basarisiz oldu."
    exit 1
  fi
else
  if "$NPM_BIN" run build; then
    print_ok "On yuz derlendi!"
  else
    print_fail "On yuz derlemesi basarisiz oldu."
    exit 1
  fi
fi

# -- Bitti -------------------------------------------------------------------
echo ""
echo "  ============================================================"
if [[ "$PLATFORM" == "Darwin" ]]; then
  echo "   Kurulum tamamlandi! Baslatmak icin ./mac.sh calistirin."
else
  echo "   Kurulum tamamlandi! Baslatmak icin ./linux.sh calistirin."
fi
echo "  ============================================================"
echo ""

if [[ "$PLATFORM" == "Linux" && $MAX_PERF -eq 0 ]] && [[ "$VENDOR" == "nvidia" || "$VENDOR" == "amd" ]]; then
  echo "  Ipucu: Maksimum GPU performansi icin su komutla tekrar calistirin:"
  echo "       ./scripts/setup/setup.sh --max-perf"
  echo ""
fi
