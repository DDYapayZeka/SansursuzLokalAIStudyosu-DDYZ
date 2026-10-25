const http = require("http");
const https = require("https");
const dns = require("dns").promises;
const net = require("net");
const zlib = require("zlib");

const USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) LocalAIStudio/1.0";

function decodeHtml(value) {
  return String(value || "")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, "<")
    .replace(/&gt;/g, ">")
    .replace(/&#x([0-9a-f]+);/gi, (_, hex) => String.fromCodePoint(parseInt(hex, 16)))
    .replace(/&#(\d+);/g, (_, num) => String.fromCodePoint(parseInt(num, 10)));
}

function isPrivateIpv4(ip) {
  const parts = String(ip || "").split(".").map((part) => Number(part));
  if (parts.length !== 4 || parts.some((part) => !Number.isInteger(part))) return true;
  const [a, b] = parts;
  return a === 0 ||
    a === 10 ||
    a === 127 ||
    (a === 169 && b === 254) ||
    (a === 172 && b >= 16 && b <= 31) ||
    (a === 192 && b === 168) ||
    a >= 224;
}

function isPrivateIpv6(ip) {
  const value = String(ip || "").toLowerCase();
  // Handle IPv4-mapped IPv6 addresses (e.g. ::ffff:127.0.0.1)
  if (value.startsWith("::ffff:") && value.includes(".")) {
    const ipv4Part = value.slice(7);
    return isPrivateIpv4(ipv4Part);
  }
  return value === "::1" ||
    value.startsWith("fc") ||
    value.startsWith("fd") ||
    value.startsWith("fe80:") ||
    value.startsWith("fec0:") ||
    value.startsWith("ff00:") ||
    value === "::";
}

function isPrivateIp(ip) {
  const family = net.isIP(ip);
  if (family === 4) return isPrivateIpv4(ip);
  if (family === 6) return isPrivateIpv6(ip);
  return true;
}

async function assertPublicUrl(rawUrl) {
  if (!rawUrl || typeof rawUrl !== "string") {
    throw new Error("Invalid URL provided.");
  }
  // Mitigate CVE-2026-105482: NUL byte truncation / control char bypass
  if (rawUrl.includes("\0") || /[\u0000-\u001f\u007f]/.test(rawUrl)) {
    throw new Error("URL contains illegal characters.");
  }
  const parsed = new URL(rawUrl);
  if (!["http:", "https:"].includes(parsed.protocol)) {
    throw new Error("Only HTTP and HTTPS URLs can be fetched.");
  }
  // Normalize unicode hostname (NFKC) and mitigate CVE-2026-105483
  const host = parsed.hostname.normalize("NFKC").toLowerCase();
  if (host === "localhost" || host.endsWith(".localhost") || host.endsWith(".local") || host.endsWith(".internal")) {
    throw new Error("Localhost and internal network URLs are blocked.");
  }
  if (net.isIP(host) && isPrivateIp(host)) {
    throw new Error("Private network URLs are blocked.");
  }
  const records = await dns.lookup(host, { all: true, verbatim: false });
  if (!records.length || records.some((record) => isPrivateIp(record.address))) {
    throw new Error("Private network addresses are blocked.");
  }
}

function stripHtml(html) {
  const withoutNoise = String(html || "")
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<noscript[\s\S]*?<\/noscript>/gi, " ")
    .replace(/<svg[\s\S]*?<\/svg>/gi, " ")
    .replace(/<nav[\s\S]*?<\/nav>/gi, " ")
    .replace(/<footer[\s\S]*?<\/footer>/gi, " ")
    .replace(/<header[\s\S]*?<\/header>/gi, " ");
  const title = decodeHtml((withoutNoise.match(/<title[^>]*>([\s\S]*?)<\/title>/i)?.[1] || "").replace(/\s+/g, " ").trim());
  const mainMatch = withoutNoise.match(/<main[^>]*>([\s\S]*?)<\/main>/i) ||
    withoutNoise.match(/<article[^>]*>([\s\S]*?)<\/article>/i) ||
    withoutNoise.match(/<body[^>]*>([\s\S]*?)<\/body>/i);
  const contentHtml = mainMatch ? mainMatch[1] : withoutNoise;
  const text = decodeHtml(contentHtml
    .replace(/<\/(p|div|section|article|main|h[1-6]|li|tr)>/gi, "\n")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<[^>]+>/g, " ")
    .replace(/[ \t\f\v]+/g, " ")
    .replace(/\n\s+/g, "\n")
    .replace(/\n{3,}/g, "\n\n")
    .trim());
  return { title, text };
}

function decodeBody(buffer, encoding) {
  const value = String(encoding || "").toLowerCase();
  if (value.includes("gzip")) {
    try {
      return zlib.gunzipSync(buffer).toString("utf8");
    } catch (_) {}
  }
  if (value.includes("deflate")) {
    try {
      return zlib.inflateSync(buffer).toString("utf8");
    } catch (_) {}
  }
  if (value.includes("br")) {
    try {
      return zlib.brotliDecompressSync(buffer).toString("utf8");
    } catch (err) {
      console.warn("  [search] Brotli decompression fallback:", err.message);
    }
  }
  return buffer.toString("utf8");
}

async function fetchPageContent(rawUrl, options = {}, redirects = 0) {
  await assertPublicUrl(rawUrl);
  const timeoutMs = Math.max(3000, Math.min(20000, Number(options.timeoutMs) || 10000));
  const maxBytes = Math.max(64 * 1024, Math.min(2 * 1024 * 1024, Number(options.maxBytes) || 768 * 1024));
  const parsed = new URL(rawUrl);
  const transport = parsed.protocol === "https:" ? https : http;

  return new Promise((resolve, reject) => {
    const req = transport.get(parsed, {
      headers: {
        "User-Agent": USER_AGENT,
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.2",
        "Accept-Encoding": "gzip, deflate, br;q=0.8",
      },
      timeout: timeoutMs,
    }, async (res) => {
      if (res.statusCode >= 300 && res.statusCode < 400 && res.headers.location && redirects < 3) {
        res.resume();
        try {
          const nextUrl = new URL(res.headers.location, parsed).toString();
          resolve(await fetchPageContent(nextUrl, options, redirects + 1));
        } catch (err) {
          reject(err);
        }
        return;
      }
      const contentType = String(res.headers["content-type"] || "").toLowerCase();
      if (res.statusCode < 200 || res.statusCode >= 300 || (!contentType.includes("text/") && !contentType.includes("html") && !contentType.includes("xml"))) {
        res.resume();
        reject(new Error(`Page returned HTTP ${res.statusCode || "unknown"} or unsupported content type.`));
        return;
      }
      const chunks = [];
      let bytes = 0;
      res.on("data", (chunk) => {
        bytes += chunk.length;
        if (bytes > maxBytes) {
          req.destroy(new Error("Page content is too large."));
          return;
        }
        chunks.push(chunk);
      });
      res.on("end", () => {
        try {
          const html = decodeBody(Buffer.concat(chunks), res.headers["content-encoding"]);
          resolve(stripHtml(html));
        } catch (err) {
          reject(err);
        }
      });
    });
    req.on("timeout", () => req.destroy(new Error("Page fetch timed out.")));
    req.on("error", reject);
  });
}

module.exports = {
  fetchPageContent,
};
