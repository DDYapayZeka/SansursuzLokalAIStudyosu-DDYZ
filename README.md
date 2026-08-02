# Sansursuz Lokal AI Studyosu - DD:YZ

<p align="center">
  <img src="NOBGLOGO.png" alt="Sansursuz Lokal AI Studyosu - DD:YZ logosu" width="180" />
</p>

<p align="center">
  <strong>Windows, Linux ve macOS icin tamamen cantasiz, kurulum gerektirmeyen ve tamamen yerel bir AI studYosu: Stable Diffusion (Gorsel Uretimi), LLM'ler (Sohbet), Whisper (Sesten Metne) ve Kokoro (Metinden Sese). NVIDIA/AMD/Intel GPU ve Apple NPU hizlandirmasi ile calisir.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Cevrimdisi-100%25-yesil?style=for-the-badge&logo=offline" alt="%100 Cevrimdisi" />
  <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-mavi?style=for-the-badge" alt="Platformlar" />
  <img src="https://img.shields.io/badge/Lisans-MIT-turuncu?style=for-the-badge" alt="Lisans" />
</p>

<p align="center">
  <a href="https://youtu.be/yeFvP3SWMak">Kurulum ve Tanitim Videosunu Izleyin</a>
</p>

---

## Icerik

* [Sansursuz Lokal AI Studyosu - DD:YZ Nedir?](#nedir)
* [One Cikan Ozellikler](#ozellikler)
* [Calisma Alani ve Motor Mimarisi](#mimari)
* [Desteklenen Modeller](#modeller)
* [Klasor Yapisi](#yapi)
* [Baslarken](#baslarken)
  * [Windows Kurulumu](#windows-kurulumu)
  * [Linux Kurulumu](#linux-kurulumu)
  * [macOS Kurulumu](#macos-kurulumu)
* [Donanim Uyumlulugu ve Hizlandirma](#donanim)
* [Sorun Giderme ve SSS](#sss)
* [Kaynaktan Derleme](#derleme)
* [Lisans](#lisans)

---

## <a id="nedir"></a> Sansursuz Lokal AI Studyosu - DD:YZ Nedir?

**Sansursuz Lokal AI Studyosu - DD:YZ**, Windows, Linux ve macOS icin tamamen cevrimdisi, kurulum gerektirmeyen ve kendi icine yeterli bir AI studYosudur. Bulut tabanli sistemlerin aksine; sansur, izleme, abonelik veya giris zorunlulugu olmadan tamamen kendi donaniminiz uzerinde calisir.

Dort ana yerel AI yetenegini tek bir yuksek performansli masaustu arayuzunde birlestirir:

1. **Gorsel Uretimi (Stable Diffusion):** `.safetensors`, `.gguf` veya `.ckpt` model agirliklari ile cevrimdisi yuksek kaliteli gorseller uretun ve duzenleyin.
2. **Metin Sohbeti (LLM'ler):** Resmi ve yuksek performansli `llama.cpp` altyapisi ile acik kaynakli dil modelleriyle (GGUF formatinda) ozel olarak sohbet edin.
3. **Sesten Metne (Whisper):** Entegre `whisper.cpp` motoru ile ses kayitlarini ve konusmalari gercek zamanli olarak metne donusturun.
4. **Metinden Sese (Kokoro TTS):** `Kokoro-82M` ONNX modelini kullanarak metin ciktilarini cevrimdisi olarak dogal ve gercekci seslere donusturun.

---

## <a id="ozellikler"></a> One Cikan Ozellikler

* **%100 Cevrimdisi ve Ozel:** Cikarimlari yerel olarak calistirin. Internet, telemetri, bulut gunlugu veya API anahtari gerekmez.
* **Kurulum Gerektirmez:** Tum calisma ortami kendi icinde bagimsizdir.
* **Otomatik Hizlandirma:** Donanim ozelliklerini otomatik algilayarak CUDA, ROCm, Vulkan, Metal veya OpenVINO motorlarini yukler.
* **Entegre Model Yoneticisi:** Hugging Face URL'leri ile kolay indirme.
* **Canli Performans Izleme:** CPU, RAM, GPU ve VRAM kullanimi web arayuzunde.
* **Yerel Cikti Galerisi:** Uretilen gorselleri ipucu parametreleri ve meta veri JSON dosyalari ile birlikte kaydeder.

---

## <a id="mimari"></a> Calisma Alani ve Motor Mimarisi

Sistem RAM'ini veya VRAM'i tuketmemek icin metin ve gorsel motorlari varsayilan olarak karsilikli harictir. Arayuz icinden calisma alanlari arasinda gecis yapabilirsiniz:

* **Gorsel Uretimi Calisma Alani:** Ozel bir `stable-diffusion.cpp` arka uc dugumu kullanir. Model agirliklari `app/models/` icinde tutulur.
* **Metin Sohbeti Calisma Alani:** Tasinabilir `llama.cpp` sunucu arka ucu kullanir. Model agirliklari (`.gguf`) `app/llm-models/` icinde tutulur.
* **Konusma Isleyicisi (Whisper):** Sesli girdinizi metne donusturur.
* **Ses Ciktilari (Kokoro TTS):** `kokoro-js` ile dogal ses uretimi yapar.

---

## <a id="modeller"></a> Desteklenen Modeller

Uygulama, paketlenmis arka uc motorlari tarafindan dogrudan yuklenebilen tek dosyalik yerel modeller etrafinda tasarlanmistir.

### Gorsel uretimi

| Model tipi | Destekleniyor mu? | Dosyalari suraya koyun | Notlar |
| :--- | :--- | :--- | :--- |
| Stable Diffusion 1.5 kontrol noktalari | Evet | `app/models/` | En iyi uyumluluk. `.safetensors` veya `.ckpt` dosyasi kullanin. |
| SDXL kontrol noktalari | Evet | `app/models/` | Tek dosyalik kontrol noktasi olarak desteklenir. SD 1.5'ten daha fazla RAM/VRAM gerektirir. |
| Tek dosyalik SD/SDXL GGUF kontrol noktalari | Sinirli | `app/models/` | Yalnizca tamamlanmis tek dosyalik kontrol noktalari desteklenir. |
| OpenVINO gorsel model klasorleri | Yalnizca Intel NPU | `app/openvino-models/` | OpenVINO kurulumundan sonra Model Yoneticisi'nden indirin. |
| CoreML gorsel modelleri | Yalnizca Apple Silicon | `app/models/` | macOS uzerinde Apple Silicon ve CoreML kurulum yolu gerektirir. |
| Flux, HiDream, Hunyuan, Wan, Qwen Image, Z-Image is akislari | Hayir | Yok | Bunlar ayri difuzyon, VAE ve metin kodlayici dosyalari gerektirir; bu uygulamada tek tiklama kontrol noktasi yuklemesi degildir. |
| LoRA, ControlNet, yalnizca VAE, yalnizca metin kodlayici veya yalnizca difuzyon dosyalari | Hayir | Yok | Yardimci dosyalar bagimsiz gorsel model olarak yuklenmez. |

Model Yoneticisi'nden edinilebilecek bilinen iyi gorsel modeller:

| Ad | Dosya adi | Tip | Yaklasik boyut | Onerilen kullanim |
| :--- | :--- | :--- | :--- | :--- |
| Juggernaut XL v9 Lightning | `Juggernaut_RunDiffusionPhoto2_Lightning_4Steps.safetensors` | SDXL | 6.6 GB | Orta/ust seviye makinelerde yuksek kaliteli fotogercekcilik. |
| DreamShaper XL Lightning | `DreamShaperXL_Lightning.safetensors` | SDXL | 6.6 GB | Genel SDXL gorselleri, fantezi, render ve illustrasyon. |
| DreamShaper 8 | `DreamShaper_8_pruned.safetensors` | SD 1.5 | 2.1 GB | Daha hizli, dusuk bellekli gorsel uretimi. |
| CyberRealistic V8 | `CyberRealistic_V8_FP16.safetensors` | SD 1.5 | 2.0 GB | Gercekci SD 1.5 gorselleri ve dusuk bellekli sistemler. |
| Rev Animated | `rev-animated-v1-2-2.safetensors` | SD 1.5 | 2.0 GB | Stilize/animasyon SD 1.5 gorselleri. |
| LCM DreamShaper OpenVINO | `OpenVINO/LCM_Dreamshaper_v7-fp16-ov` | OpenVINO | 2.7 GB | Intel Core Ultra NPU test modeli. |

### Metin, konusma ve TTS

| Calisma alani | Desteklenen model dosyalari | Dosyalari suraya koyun | Notlar |
| :--- | :--- | :--- | :--- |
| Metin Sohbeti | `.gguf` llama.cpp modelleri | `app/llm-models/` | Tek dosyalik GGUF sohbet/ogretim modelleri kullanin. Gorsel modeller uyumlu `mmproj` dosyasi da gerektirebilir. |
| Sesten Metne | whisper.cpp `.bin` modelleri | `app/speech-models/` | Whisper GGML/whisper.cpp model dosyalari kullanin. |
| Metinden Sese | Kokoro `.json` bildirimleri ve model varliklari | `app/tts-models/` / `app/tts-runtime/` | Yerlesik Kokoro kurulumunu ve Model Yoneticisi girislerini kullanin. |

> Linux yayin ikilileri Ubuntu 24.04 donemi sistemler icin derlenmistir ve `glibc 2.38+` ile `GLIBCXX_3.4.32+` gerektirir. Eski Ubuntu/Debian uzerinde CyberRealistic gibi gecerli bir model yine de yuklenmeden once arka uc hata verebilir. VM isletim sistemini guncelleyin veya arka ucu kaynaktan derleyin.

---

## <a id="yapi"></a> Klasor Yapisi

```
Sansursuz-Lokal-AI-Studyosu-DDYZ/
+-- windows.bat                # Windows Baslatici (Cift tiklama giris noktasi)
+-- linux.sh                   # Linux Baslatici (Terminal giris noktasi)
+-- mac.sh                     # macOS Baslatici (Terminal giris noktasi)
+-- LICENSE                    # MIT Acik Kaynak Lisansi
+-- .gitignore                 # Modelleri ve cikti gorsellerini surum kontrolu disinda birakir
+-- README.md                  # Ayrintili sistem dokumantasyonu
+-- scripts/
|   +-- setup/                 # Platform kurulumu ve arka uc yukleyicileri
|   +-- reset/                 # Temiz kurulum ve ortam onarimi
|   +-- server/                # UI web sunucusu ve arka uc yasam dongusu yoneticisi
|   +-- workers/               # Yerel isci surecleri
|   +-- build/                 # Istege bagli kaynak derleme yardimcilari
|   +-- config/                # Calisma zamani yapilandirma kataloglari
+-- app/
    +-- frontend/              # Arayuz kaynak kodu (Vite + React)
    +-- models/               # Gorsel agirliklarini buraya koyun (.safetensors, .gguf, .ckpt)
    +-- llm-models/           # Metin GGUF agirliklarini buraya koyun
    +-- outputs/              # Kaydedilen gorseller ve parametre meta verileri
```

---

## <a id="baslarken"></a> Baslarken

Modern bir web tarayicisi kurulu oldugundan emin olun. Platformunuz icin asagidaki kilavuzu izleyin:

### Windows Kurulumu

1. **Baslatma:** `windows.bat` dosyasina cift tiklayin.
   > Ilk calistirmada betik, tasinabilir bir Node.js calisma ortami indirecek ve onceden derlenmis GPU/CPU arka uc ikililerini yapilandirir.
2. **Model Ekleyin:** `.safetensors`, `.gguf` veya `.ckpt` agirliklarini `app/models/` icine birakin (veya bunlari arayuzdeki **Model Yoneticisi** sekmesinden indirin).
3. **Uretin:** Tarayicinizda `http://localhost:1420` adresini acin, modelinizi secin ve bir ipucu yazin.

### Linux Kurulumu

1. **Calistirilabilir yapin:** Proje klasorunde bir terminal acin ve betigi calistirilabilir yapin:
   ```bash
   chmod +x linux.sh
   ```
2. **Baslatma:** `./linux.sh` calistirin.
   - **NVIDIA GPU Kullanicilari:** Yuksek performansli **CUDA** arka ucunu kurmak icin size sorulacak (onceden derlenmis ikili indirir veya yedek olarak kaynaktan derler).
   - **AMD Radeon Performansi:** ROCm arka ucunu eklemek icin `./linux.sh --max-perf` ile calistirin (~1.3 GB indirme).
   - **Intel Core Ultra NPU:** Intel NPU destegi icin `./linux.sh --setup-openvino` ile calistirin (Intel Linux NPU surucusu gerekir).
3. **Model Ekleyin:** Agirliklarinizi `app/models/` icine birakin veya **Model Yoneticisi** sekmesinden indirin.
4. **Uretin:** Tarayicinizda `http://localhost:1420` adresini acin.

### macOS Kurulumu

1. **Calistirilabilir yapin:** Proje klasorunde bir terminal acin ve betigi calistirilabilir yapin:
   ```bash
   chmod +x mac.sh
   ```
2. **Baslatma:** `./mac.sh` calistirin.
   > Onceden derlenmis macOS arka ucu **Apple Silicon (M1 veya daha yeni)** icin optimize edilmistir ve **Metal** GPU hizlandirmasi kullanir. (macOS Intel donanimi tamamen desteklenmez).
3. **Model Ekleyin:** Agirliklarinizi `app/models/` icine birakin veya **Model Yoneticisi** sekmesinden indirin.
4. **Uretin:** Tarayicinizda `http://localhost:1420` adresini acin.

---

## <a id="donanim"></a> Donanim Uyumlulugu ve Hizlandirma

### Windows

| GPU Ureticisi | Teknoloji | Durum | Notlar |
| :--- | :--- | :--- | :--- |
| **Nvidia** | CUDA | Yerel | `sd-cuda.exe` dosyasini Nvidia SDK 12 iyilestirmeleriyle esler. |
| **AMD Radeon** | Vulkan | Yerel | `sd-vulkan.exe` dosyasini Vulkan API hizlandirmasiyla esler. |
| **Intel Arc** | Vulkan | Yerel | Intel donanimi icin `sd-vulkan.exe` kullanir. |
| **Entegre / Yok** | CPU | Yedek | Mantik islemci thread'leri uzerinde calisir (yavas). |

### Linux

| GPU Ureticisi | Birincil | Yedek | Notlar |
| :--- | :--- | :--- | :--- |
| **NVIDIA** | CUDA / Vulkan | Vulkan / CPU | NVIDIA'yi otomatik algilar. CUDA kurulumu onceden derlenmis indirir veya kaynaktan derler. GTX icin Vulkan'a duser. |
| **AMD Radeon** | ROCm | Vulkan | ROCm, ana makinede ROCm suruculeri varsa en iyi AMD performansini saglar. |
| **Intel Arc / entegre** | Vulkan | CPU | Cok ureticili Vulkan destegi. |
| **Intel Core Ultra NPU** | OpenVINO NPU | CPU | Intel Linux NPU surucusu, kernel 6.6+, Python 3 ve `./linux.sh --setup-openvino` gerektirir. |
| **Entegre / Yok** | CPU | - | Mantik islemci thread'leri uzerinde calisir (yavas). |

### macOS

| Donanim | Birincil | Yedek | Notlar |
| :--- | :--- | :--- | :--- |
| **Apple Silicon (M1 veya daha yeni)** | Metal | CPU | Resmi Darwin arm64 stable-diffusion.cpp arka ucunu kullanir. |

> **Sistem Gereksinimleri ve Notlar:**
> - Windows baslatici tarafindan kullanilan tasinabilir Node.js 22 calisma ortami icin **64-bit Windows 10 veya Windows 11** gereklidir.
> - Onceden derlenmis Linux arka uclari icin **glibc 2.38 veya daha yeni** (Ubuntu 24.04, Fedora 40+ vb.) gereklidir. Kurulum betigi glibc eskiyse sizi uyarir.
> - Linux calisma zamani kutuphaneleri: Onceden derlenmis arka uclar `libgomp.so.1` gerektirir; Vulkan ayrica `libvulkan.so.1` ve calisan bir GPU surucusu gerektirir. Kurulum betigi bir arka uc yuklemeden once bunlari kontrol eder ve eksik oldugunda tam distro paket komutunu yazar.
> - Linux OpenVINO NPU: Intel Core Ultra, x86_64 Linux, kernel 6.6+, calisan bir `/dev/accel/accel0` aygiti, Python 3 (venv ile) ve Intel Linux NPU surucusu gereklidir.

---

## <a id="sss"></a> Sorun Giderme ve SSS

**Ortami Sifirla:** Bir derleme basarisiz olursa veya bagimliliklari temizlemek isterseniz `scripts/reset/reset.ps1` (Windows) veya `scripts/reset/reset.sh` (Linux/macOS) calistirin. Bu, gecici derleme ve paket onbellegini temizleyerek ortaminizi onarir. (Model agirliklariniz ve uretilen cikti gorselleriniz korunur.)

**Linux arka uclari `GLIBC_2.38 not found` ile baslamiyor:** Onceden derlenmis ikililer glibc 2.38+ gerektirir (orn. Ubuntu 24.04). Dagitiminiz daha eski bir glibc surumu kullaniyorsa isletim sistemini guncelleyebilir veya arka ucu kaynaktan derleyebilirsiniz (asagidaki Kaynaktan Derleme kilavuzuna bakin).

**Port Cakismalari: Varsayilan port adresi mesgul:** Web kullanici arayuzu varsayilan olarak `1420` portunda calisir. GPU arka uc yoneticisi once `8080` portunu baglamayi dener, sonra otomatik olarak bos bir sistem portu algilar ve duser.

**Linux ROCm AMD Radeon GPU'lar icin yuklenmiyor:** AMD GPU donaniminizin ve ana makine kernel'inizin ROCm 7.13 ile tam uyumlu oldugundan emin olun. ROCm dogru baslatilmazsa uygulama otomatik olarak Vulkan hizlandirmaya duser.

**Linux ayri GPU yerine entegre GPU kullaniyor:** Cift GPU'lu Linux sistemlerinde Vulkan aygit siralamasi entegre Intel GPU'yu `vulkan0`, ayri AMD/NVIDIA GPU'yu `vulkan1` yapabilir. Baslatici, `vulkaninfo --summary` varsa ayri bir Vulkan aygitini tercih etmeye calisir. Aygiti elle zorlamak icin uygulamayi `SD_VULKAN_DEVICE=vulkan1 ./linux.sh` ile calistirin.

**Windows `3221225781` (0xC0000135) kodu ile cikiyor:** Bu kod, Windows'in gerekli bir arka uc DLL'ini bulamadigi anlamina gelir:
- **AMD/Intel Vulkan icin:** GPU surucunuzu tam Vulkan calisma zamani destegi olan bir surume guncelleyin, sonra kurulum betigini tekrar calistirarak `app/backend/win/vulkan/` klasorunu geri yukleyin.
- **NVIDIA CUDA icin:** NVIDIA grafik surucunuzu kurun veya guncelleyin, sonra kurulum betigini tekrar calistirarak CUDA calisma zamani DLL'lerini geri yukleyin.

**Uretim "sunucu yanit vermiyor veya coktu" diyor:** Bu, yerel arka uc motoru surecinin sona erdigi anlamina gelir. Baslatma terminalinizde (windows.bat, ./linux.sh veya ./mac.sh calistirdiginiz yer) tam konsol hatasini kontrol edin. Yaygin nedenler glibc surum uyumsuzluklari, eksik Vulkan suruculeri veya sistem bellek yetersizligidir (OOM).

---

## <a id="derleme"></a> Kaynaktan Derleme

Kurulum betigi (`scripts/setup/setup.sh`), secildiginde CUDA arka ucunu kaynaktan derlemeyi ve kurmayi otomatiklestirir. Tum arka uclari (CPU, Vulkan ve CUDA) birlikte elle derlemek icin `scripts/build/build_from_source.sh` betigini calistiralabilirsiniz.

macOS icin `scripts/build/build_from_source.sh` Metal arka ucunu derler ve `app/backend/mac/sd` konumuna kopyalar.

### Gereksinimler
- `git`, `cmake`, `make` (veya `ninja`) ve bir C++17 derleyici (`g++` / `clang++`).
- **CUDA icin:** NVIDIA CUDA arac takimi (`nvcc`) PATH'te olmali.
- **Vulkan icin:** Vulkan SDK/yukleyici, uyumlu surucu ve `glslc` (Ubuntu/Debian paketi: `glslc`).
- **ROCm icin:** AMD ROCm gelistirme kutuphaneleri.
- **macOS Metal icin:** Apple Command Line Tools veya Xcode.

### Derleme komutlari

```bash
# 1. Ust depoyu kopyalayin
git clone https://github.com/leejet/stable-diffusion.cpp.git
cd stable-diffusion.cpp
mkdir build && cd build

# 2. Arka ucunuz icin yapilandirin (bunlardan BIRINI secin)
# Yalnizca CPU
cmake .. -DSD_BUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release

# CUDA
cmake .. -DSD_CUDA=ON -DSD_BUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release

# Vulkan
cmake .. -DSD_VULKAN=ON -DSD_BUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release

# ROCm
cmake .. -DSD_HIPBLAS=ON -DSD_BUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release

# macOS Metal
cmake .. -DSD_METAL=ON -DSD_BUILD_SHARED_LIBS=ON -DCMAKE_BUILD_TYPE=Release

# 3. Derleyin
cmake --build . --config Release -j$(getconf _NPROCESSORS_ONLN 2>/dev/null || sysctl -n hw.ncpu)

# 4. Ikilileri bu projeye kopyalayin
cp bin/sd* /yol/Sansursuz-Lokal-AI-Studyosu-DDYZ/app/backend/linux/<arka uc>/
```

Kopyaladiktan sonra sunucu ikilisini `scripts/server/serve.cjs` dosyasinin bekledigi ada yeniden adlandirin:
- Vulkan: `sd` -> `sd-vulkan`
- ROCm: `sd` -> `sd-rocm`

Ardindan uygulamayi `./linux.sh` (Linux) veya `./mac.sh` (macOS) ile yeniden baslatin.

---

## <a id="lisans"></a> Lisans

Bu proje MIT Lisansi ile lisanslanmistir - [LICENSE](LICENSE) dosyasina bakin. [stable-diffusion.cpp](https://github.com/leejet/stable-diffusion.cpp) (MIT Lisansi) paketlenmistir. Model agirliklari kendi olusturucularinin lisanslarina tabidir.

---

## <a id="tesekkur"></a> Tesekkur ve Atif

Bu proje, [techjarves](https://github.com/techjarves)'in ozgun **[Uncensored-Local-Studio](https://github.com/techjarves/Uncensored-Local-Studio)** projesinin yeniden duzenlenmis (refactoring) bir halidir. Ozgun calismasi olmadan bu calma yerel AI araci mumkun olmazdi; emegine ve acik kaynak katkisina ictenlikle tesekkur ederiz.

* Ozgun proje: [https://github.com/techjarves/Uncensored-Local-Studio](https://github.com/techjarves/Uncensored-Local-Studio)
* Bu repo, ozgun kod tabaninin Turkce (ASCII) yerellestirme, arayuz iyilestirme ve "Tum Varsayilan Modelleri Indir" ozelligi eklenmis surumudur.
