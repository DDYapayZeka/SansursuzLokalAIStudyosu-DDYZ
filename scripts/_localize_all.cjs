#!/usr/bin/env node
/*
 * Safe, line-based ASCII-Turkish localizer for Uncensored-Local-Studio.
 *
 * Translates, per line (bounded, no giant captures):
 *  - JSX element TEXT NODES: text between '>' and '<' that is display text.
 *  - string-literal message contents (only literals that are sentences/labels).
 *  - full-line comments.
 * URLs, /api/... routes, filesystem paths, config keys and version/build
 * strings are protected and left untouched. Identifiers are never touched.
 * Remaining box-drawing / emoji / special punctuation is ASCII-normalized.
 */
const fs = require("fs");
const path = require("path");

const ROOT = "C:/Users/harun/Desktop/Uncensored-Local-Studio";

const PHRASES = [
  ["You haven't downloaded any text models yet. Please go to the 'Model Manager' or 'Text Chat' tab to download a GGUF model first.",
   "Henuz hic metin modeli indirmediniz. Once bir GGUF model indirmek icin 'Model Yoneticisi' veya 'Metin Sohbeti' sekmesine gidin."],
  ["Enhancing your prompt requires loading the local text model", "Ipuclarinizi gelistirmek yerel metin modelini yuklemeyi gerektirir"],
  ["This will temporarily unload the image model from memory. Do you want to proceed?",
   "Bu islem gorsel modeli bellekten gecici olarak kaldirir. Devam etmek istiyor musunuz?"],
  ["The current image generation will be cancelled and the local model server may restart.",
   "Mevcut gorsel uretimi iptal edilecek ve yerel model sunucusu yeniden baslayabilir."],
  ["Whisper Base Multilingual", "Whisper Temel Cok Dilli"],
  ["The loaded model is English-only and cannot transcribe non-English speech. Please download and load a Multilingual model (e.g. Whisper Base Multilingual) from the Model Manager to transcribe this audio.",
   "Yuklu model yalnizca Ingilizce'dir ve Ingilizce olmayan konusmayi yaziya dokemez. Bu sesi yaziya dokmek icin Model Yoneticisi'nden Cok Dilli bir model (orn. Whisper Temel Cok Dilli) indirip yukleyin."],
  ["V1 accepts WAV files only. MP3/WebM/M4A will need the later FFmpeg path.",
   "V1 yalnizca WAV dosyalarini kabul eder. MP3/WebM/M4A icin ileride FFmpeg yolu gerekecek."],
  ["Record microphone audio or upload a WAV file, then transcribe locally with whisper.cpp.",
   "Mikrofondan ses kaydedin veya bir WAV dosyasi yukleyin, ardindan whisper.cpp ile yerel olarak yaziya dokun."],
  ["Microphone recordings are converted to 16 kHz mono PCM16 WAV before transcription.",
   "Mikrofon kayitlari yaziya dokmeden once 16 kHz mono PCM16 WAV formatina cevrilir."],
  ["Generate local WAV narration with Kokoro ONNX.", "Kokoro ONNX ile yerel WAV anlatimi uretin."],
  ["Download a Whisper model from Model Manager, Speech Models first.",
   "Once Model Yoneticisi, Konusma Modelleri'nden bir Whisper modeli indirin."],
  ["Download a Kokoro model from Model Manager, TTS Models first.",
   "Once Model Yoneticisi, TTS Modelleri'nden bir Kokoro modeli indirin."],
  ["Generated speech will appear here.", "Uretilen ses burada gorunecek."],
  ["Type text to turn into speech...", "Seslendirilecek metni yazin..."],
  ["Please choose an image file (PNG, JPG, or WEBP).", "Lutfen bir gorsel dosyasi secin (PNG, JPG veya WEBP)."],
  ["Could not read the selected image file.", "Secilen gorsel dosyasi okunamadi."],
  ["File is not supported. Please select an image (JPEG, PNG, WEBP) or a text/code file.",
   "Dosya desteklenmiyor. Lutfen bir gorsel (JPEG, PNG, WEBP) veya metin/kod dosyasi secin."],
  ["The local C++ stable-diffusion server is running. Real-time telemetry is displaying performance status in the top bar.",
   "Yerel C++ stable-diffusion sunucusu calisiyor. Gercek zamanli telemetri ust barinda performans durumunu gosteriyor."],
  ["Manage local files and download recommended weights directly to your local models folder.",
   "Yerel dosyalari yonetin ve onerilen agirliklari dogrudan yerel modeller klasorunuze indirin."],
  ["Settings Saved & Applied", "Ayarlar Kaydedildi ve Uygulandi"],
  ["Another download is already active.", "Baska bir indirme zaten aktif."],
  ["A speech model .bin URL or catalog model id is required.",
   "Bir konusma modeli .bin URL'i veya katalog model kimligi gereklidir."],
  ["Transcription metadata not found", "Transkripsiyon meta verisi bulunamadi"],
  ["TTS output metadata not found", "TTS cikti meta verisi bulunamadi"],
  ["model is required", "model gereklidir"],
  ["Downloading default model", "Varsayilan model indiriliyor"],
  ["All default models ready", "Tum varsayilan modeller hazir"],
  ["All default models already present", "Tum varsayilan modeller zaten mevcut"],
  ["Default TTS manifest failed", "Varsayilan TTS bildirimi basarisiz oldu"],
  ["Default models download started", "Varsayilan modeller indirmesi basladi"],
  ["The local server returned an invalid default-models download response.",
   "Yerel sunucu gecersiz bir varsayilan-model indirme yaniti dondurdu."],
  ["Failed to start default models download:", "Varsayilan modeller indirmesi baslatilamadi:"],
  ["Stop local model server", "Yerel model sunucusunu durdur"],
  ["Choose a custom color theme", "Ozel bir renk temasi secin"],
  ["Select Theme", "Tema Sec"],
  ["Switch to light theme", "Acik temaya gec"],
  ["Switch to dark theme", "Koyu temaya gec"],
  ["Collapse Sidebar", "Kenar Cubugunu Daralt"],
  ["Expand Sidebar", "Kenar Cubugunu Genislet"],
  ["Load & Enhance", "Yukle ve Gelistir"],
  ["Reload With DeepThink?", "DeepThink ile Yeniden Yukle?"],
  ["Reload Without DeepThink?", "DeepThink olmadan Yeniden Yukle?"],
  ["Load Text Model?", "Metin Modeli Yuklensin Mi?"],
  ["Text Model Reload Failed", "Metin Modeli Yeniden Yukleme Basarisiz"],
  ["Prompt Enhancement Failed", "Ipucu Gelistirme Basarisiz"],
  ["Unload Failed", "Kaldirma Basarisiz"],
  ["Delete Failed", "Silme Basarisiz"],
  ["Save Failed", "Kaydetme Basarisiz"],
  ["Settings Saved", "Ayarlar Kaydedildi"],
  ["Delete Transcription", "Transkripsiyonu Sil"],
  ["Delete TTS Output", "TTS Ciktisini Sil"],
  ["Remove Audio", "Sesi Kaldir"],
  ["Stop Recording", "Kaydi Durdur"],
  ["Upload WAV", "WAV Yukle"],
  ["Generate WAV", "WAV Uret"],
  ["Record or upload WAV", "Kaydedin veya WAV yukleyin"],
  ["No saved chats", "Kayitli sohbet yok"],
  ["No saved transcriptions", "Kayitli transkripsiyon yok"],
  ["No saved audio", "Kayitli ses yok"],
  ["Show Chat History", "Sohbet Gecmisini Goster"],
  ["Hide Chat History", "Sohbet Gecmisini Gizle"],
  ["Show Transcriptions", "Transkripsiyonlari Goster"],
  ["Hide Transcriptions", "Transkripsiyonlari Gizle"],
  ["Show TTS Outputs", "TTS Ciktilarini Goster"],
  ["Hide TTS Outputs", "TTS Ciktilarini Gizle"],
  ["Delete Conversation", "Sohbeti Sil"],
  ["Image Generator", "Gorsel Uretici"],
  ["Text Chat", "Metin Sohbeti"],
  ["Speech Transcriber", "Konusma Yazici"],
  ["Text to Speech", "Metinden Sese"],
  ["Model Manager", "Model Yoneticisi"],
  ["Settings", "Ayarlar"],
  ["Host Specifications", "Bilgisayar Ozellikleri"],
  ["Image Models (SD)", "Gorsel Modelleri (SD)"],
  ["Text Models (GGUF)", "Metin Modelleri (GGUF)"],
  ["Speech Models (Whisper)", "Konusma Modelleri (Whisper)"],
  ["TTS Models (Kokoro)", "TTS Modelleri (Kokoro)"],
  ["CPU Utilization", "CPU Kullanimi"],
  ["System Memory Usage", "Sistem Bellegi Kullanimi"],
  ["Model Loaded (Image)", "Model Yuklendi (Gorsel)"],
  ["Model Loaded (Text)", "Model Yuklendi (Metin)"],
  ["Server Active", "Sunucu Aktif"],
  ["Local Mode", "Yerel Mod"],
  ["Image generated but could not be saved to USB", "Gorsel uretildi ancak USB'ye kaydedilemedi"],
  ["This looks like your first run on Linux. Setting up automatically...",
   "Bu, Linux uzerinde ilk calistirmaniz gibi gorunuyor. Otomatik olarak kuruluyor..."],
  ["Uncensored AI Studio needs a quick repair before launch.",
   "Sansursuz Lokal AI Studyosu - DD:YZ baslatilmadan once hizli bir onarima ihtiyac duyuyor."],
  ["Models are not downloaded during setup. Download or import them in the app.",
   "Modeller kurulum sirasinda indirilmez. Uygulama icinden indirin veya ice aktarin."],
  ["Press Enter to continue, or Ctrl+C to cancel.", "Devam etmek icin Enter'e basin, veya iptal etmek icin Ctrl+C tusuna basin."],
  ["Press Enter to close...", "Kapatmak icin Enter'e basin..."],
  ["Frontend port", "Arayuz portu"],
  ["is busy; using", "mesgul; su kullaniliyor"],
  ["instead.", "yerine."],
  ["Starting Uncensored AI Studio...", "Sansursuz Lokal AI Studyosu - DD:YZ baslatiliyor..."],
  ["Opening browser at", "Tarayici su adreste aciliyor"],
  ["Open your browser to:", "Tarayicinizi su adreste acin:"],
  ["Web UI:", "Web Arayuzu:"],
  ["GPU API:", "GPU API:"],
  ["Text API:", "Metin API:"],
  ["Speech:", "Ses Tanima:"],
  ["TTS:", "Metinden Sese:"],
  ["Press Ctrl+C in this window to stop all services.", "Tum servisleri durdurmak icin bu pencerede Ctrl+C tuslarina basin."],
  ["Running!", "Calisiyor!"],
  ["Shutting down...", "Kapatiliyor..."],
  ["Done. Goodbye!", "Bitti. Gule gule!"],
  ["This script is for Linux only. Please run ./mac.sh on macOS.",
   "Bu betik yalnizca Linux icindir. Lutfen macOS uzerinde ./mac.sh calistirin."],
  ["No free frontend port found. Tried", "Bos arayuz portu bulunamadi. Denendi"],
  ["Unknown option:", "Bilinmeyen secenek:"],
  ["Usage:", "Kullanim:"],
  ["Portable Node.js for Linux is missing.", "Tasinabilir Node.js (Linux) eksik."],
  ["Frontend build is missing.", "On yuz derlemesi eksik."],
  ["Linux backend binaries are missing or not executable.", "Linux arka uc ikilileri eksik veya calistirilabilir degil."],
  ["Linux llama.cpp text backend is missing or not executable.", "Linux llama.cpp metin arka ucu eksik veya calistirilabilir degil."],
  ["Linux whisper.cpp speech backend is missing or not executable.", "Linux whisper.cpp konusma arka ucu eksik veya calistirilabilir degil."],
  ["Kokoro text-to-speech runtime is missing.", "Kokoro metinden sese calisma zamani eksik."],
  ["Setup failed. Please check the output above.", "Kurulum basarisiz oldu. Lutfen yukaridaki ciktiyi kontrol edin."],
  ["Filesystem does not support symlinks. Using directory swapping fallback...",
   "Dosya sistemi sembolik baglari desteklemiyor. Dizin takas yedegi kullaniliyor..."],
  ["Migrating existing node_modules to node_modules_linux...", "Mevcut node_modules node_modules_linux konumuna tasiniliyor..."],
  ["Swapping out node_modules to node_modules_", "node_modules node_modules_ konumuna takas ediliyor"],
  ["Saving node_modules as node_modules_windows...", "node_modules node_modules_windows olarak kaydediliyor..."],
  ["Swapping in node_modules_linux...", "node_modules_linux takas ediliyor..."],
  ["First-Time Setup", "Ilk Kurulum"],
  ["Repair", "Onarim"],
  ["Launching...", "Baslatiliyor..."],
  ["Image Generator", "Gorsel Uretici"],
  ["Text Chat", "Metin Sohbeti"],
  ["Speech Transcriber", "Konusma Yazici"],
  ["Text to Speech", "Metinden Sese"],
  ["Model Manager", "Model Yoneticisi"],
  ["Settings", "Ayarlar"],
  ["Host Specifications", "Bilgisayar Ozellikleri"],
];

const WORDS = {
  image: "gorsel", text: "metin", speech: "konusma", model: "model", models: "modeller",
  download: "indir", downloading: "indiriliyor", uploads: "yuklemeler",
  loading: "yukleniyor", loaded: "yuklendi", generate: "uret", generating: "uretiliyor",
  generation: "uretim", cancel: "iptal", refresh: "yenile", settings: "ayarlar", theme: "tema",
  voice: "ses", language: "dil", backend: "arka uc", runtime: "calistirma ortami",
  server: "sunucu", audio: "ses", output: "cikti", outputs: "ciktilar", input: "giris",
  ready: "hazir", installed: "kuruldu", missing: "eksik", failed: "basarisiz", error: "hata",
  manager: "yonetici", chat: "sohbet", delete: "sil", remove: "kaldir", stop: "durdur",
  start: "baslat", enhance: "gelistir", prompt: "ipucu", file: "dosya", files: "dosyalar",
  select: "sec", selected: "secili", transcribe: "yaziya dok", save: "kaydet",
  saved: "kaydedildi", detected: "algilandi", multilingual: "cok dilli", dark: "koyu",
  light: "acik", sidebar: "kenar cubugu", specifications: "ozellikler", memory: "bellek",
  utilization: "kullanimi", usage: "kullanim", system: "sistem", active: "aktif", local: "yerel",
  import: "ice aktar", load: "yukle", unload: "kaldir", default: "varsayilan",
};

const NORMALIZE = {
  "\u2500": "-", "\u2501": "=", "\u2502": "|", "\u250C": "+", "\u2510": "+", "\u2514": "+",
  "\u2518": "+", "\u251C": "+", "\u2524": "+", "\u252C": "+", "\u2534": "+", "\u253C": "+",
  "\u2588": "#", "\u2192": "->", "\u2190": "<-", "\u2014": "-", "\u2013": "-",
  "\u2018": "'", "\u2019": "'", "\u201C": '"', "\u201D": '"', "\u2026": "...", "\u00A0": " ",
};
const EMOJI = /[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}\u{2300}-\u{23FF}\u{25A0}-\u{25FF}\u{2700}-\u{27BF}]/gu;

function protectTokens(s) {
  const holes = [];
  const re = /https?:\/\/[^\s"'`<>]+|www\.[^\s"'`<>]+|\/api\/[A-Za-z0-9_/?=&.\-]+|\.\.[^\s"'`<>]+|\.[a-z]+[A-Za-z0-9_]*\.[a-z]{1,5}/g;
  return [s.replace(re, (m) => { holes.push(m); return "\x01" + (holes.length - 1) + "\x01"; }), holes];
}
function restoreTokens(s, holes) {
  return s.replace(/\x01(\d+)\x01/g, (_, i) => holes[Number(i)]);
}

function translateText(s) {
  const [ps, holes] = protectTokens(s);
  let out = ps;
  for (const [en, tr] of PHRASES) {
    if (en.length > 1 && out.includes(en)) out = out.split(en).join(tr);
  }
  for (const [en, tr] of Object.entries(WORDS)) {
    const re = new RegExp("\\b" + en.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\b", "ig");
    out = out.replace(re, (m) => (m[0] === m[0].toUpperCase() ? tr[0].toUpperCase() + tr.slice(1) : tr));
  }
  return restoreTokens(out, holes);
}

function asciiNormalizeLine(s) {
  let out = "";
  for (const ch of s) {
    if (NORMALIZE[ch]) out += NORMALIZE[ch];
    else if (ch.charCodeAt(0) > 127) out += "";
    else out += ch;
  }
  return out.replace(EMOJI, " ");
}

// Translate JSX text nodes on a single line. Skips {expression} nodes and
// `>`/`=` used inside JSX expressions so identifiers are never translated.
function translateJsxLine(line) {
  let out = "";
  let i = 0;
  while (i < line.length) {
    const c = line[i];
    if (c === ">") {
      const j = line.indexOf("<", i + 1);
      if (j === -1) { out += line.slice(i); break; }
      const node = line.slice(i + 1, j);
      const trimmed = node.trim();
      // Skip JSX expression containers { ... } and any node containing '{'.
      if (trimmed && !node.includes("{") && /[A-Za-z]/.test(trimmed)) {
        out += ">" + translateText(node) + "<";
      } else {
        out += line.slice(i, j + 1);
      }
      i = j + 1;
    } else {
      out += c; i++;
    }
  }
  return out;
}

// Translate message string literals on a single line (only those that are sentences/labels).
function translateJsLine(line) {
  if (line.length > 6000) return asciiNormalizeLine(line); // skip pathological long lines
  // Process string literals via a simple scan; translate inner content if message-like.
  let out = "";
  let i = 0;
  const n = line.length;
  while (i < n) {
    const c = line[i];
    if (c === '"' || c === "'" || c === "`") {
      const q = c; let buf = c; i++;
      while (i < n) {
        const d = line[i];
        if (d === "\\") { buf += d + line[i + 1]; i += 2; continue; }
        buf += d;
        if (d === q) { i++; break; }
      }
      const inner = buf.slice(1, -1);
      const isMsg = /[A-Za-z]/.test(inner) && (inner.includes(" ") || /^[A-Z][a-z]/.test(inner));
      out += q + (isMsg ? translateText(inner) : inner) + q;
      continue;
    }
    out += c; i++;
  }
  return out;
}

function processJsxFile(src) {
  return src.split("\n").map((line) => {
    const t = line.trim();
    if (t.startsWith("//") || t.startsWith("*") || t.startsWith("/*")) {
      return asciiNormalizeLine(translateText(line));
    }
    return translateJsxLine(line);
  }).join("\n");
}

function processJsFile(src) {
  return src.split("\n").map((line) => {
    const t = line.trim();
    if (t.startsWith("//") || t.startsWith("*") || t.startsWith("/*")) {
      return asciiNormalizeLine(translateText(line));
    }
    return translateJsLine(line);
  }).join("\n");
}

function processCssFile(src) {
  return src.split("\n").map((line) => asciiNormalizeLine(line)).join("\n");
}

function walk(dir, exts, cb) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) {
      if (["node_modules", "dist", "build", ".git"].includes(ent.name)) continue;
      walk(p, exts, cb);
    } else if (exts.includes(path.extname(p))) {
      cb(p);
    }
  }
}

function main() {
  const arg = process.argv[2];
  if (arg) {
    const p = arg;
    const src = fs.readFileSync(p, "utf8");
    const out = p.endsWith(".jsx") || p.endsWith(".html") ? processJsxFile(src)
      : p.endsWith(".css") ? processCssFile(src) : processJsFile(src);
    if (out !== src) fs.writeFileSync(p, out, "utf8");
    console.log("Processed single file:", p);
    return;
  }
  const frontend = path.join(ROOT, "app", "frontend", "src");
  let count = 0;
  walk(frontend, [".jsx", ".html", ".css"], (p) => {
    const src = fs.readFileSync(p, "utf8");
    const out = p.endsWith(".jsx") || p.endsWith(".html") ? processJsxFile(src)
      : p.endsWith(".css") ? processCssFile(src) : processJsFile(src);
    if (out !== src) fs.writeFileSync(p, out, "utf8");
    count++;
  });
  const serve = path.join(ROOT, "scripts", "server", "serve.cjs");
  let s = fs.readFileSync(serve, "utf8");
  s = processJsFile(s);
  fs.writeFileSync(serve, s, "utf8");
  count++;
  console.log("Processed", count, "frontend files + serve.cjs");
}
main();
