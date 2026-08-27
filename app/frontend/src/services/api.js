import { API_BASE, fetchJson, postJson } from "./apiCore";

export function isLocalServerMode() {
  return true;
}

export async function getHealth() {
  return fetchJson("/api/health");
}

export async function getBackendOptions() {
  return fetchJson("/api/backend-options");
}

export async function getDiagnostics() {
  return fetchJson("/api/diagnostics");
}

export async function getCleanupCandidates() {
  return fetchJson("/api/cleanup-candidates");
}

export async function cleanupCandidates(items) {
  return postJson("/api/cleanup", { items });
}

export async function getHardwareSpecs() {
  return fetchJson("/api/hardware-specs");
}

export async function getTelemetry() {
  return fetchJson("/api/telemetry");
}

export async function getBackendStatus() {
  return fetchJson("/api/backend-status");
}

export async function setSettings(settings) {
  return postJson("/api/settings", settings);
}

export async function listModels() {
  return fetchJson("/api/models");
}

export async function listLlmModels() {
  return fetchJson("/api/llm-models");
}

export async function listSpeechModels() {
  return fetchJson("/api/speech-models");
}

export async function listTtsModels() {
  return fetchJson("/api/tts-models");
}

export async function getCompatibleModels() {
  return fetchJson("/api/compatible-models");
}

export async function downloadDefaultModels() {
  return postJson("/api/download-default-models", {});
}

export async function downloadModel(url, filename = null) {
  return postJson("/api/download-model", { url, filename });
}

export async function downloadLlmModel(url, filename = null, companion = null) {
  return postJson("/api/download-llm-model", { url, filename, companion });
}

export async function downloadSpeechModel(url, filename = null) {
  return postJson("/api/download-speech-model", { url, filename });
}

export async function downloadTtsModel(url, filename = null) {
  return postJson("/api/download-tts-model", { url, filename });
}

export async function getDownloadProgress() {
  return fetchJson("/api/download-progress");
}

export async function cancelDownload() {
  return postJson("/api/cancel-download", {});
}

export async function deleteModel(filename) {
  return postJson("/api/delete-model", { filename });
}

export async function deleteLlmModel(filename) {
  return postJson("/api/delete-llm-model", { filename });
}

export async function deleteSpeechModel(filename) {
  return postJson("/api/delete-speech-model", { filename });
}

export async function deleteTtsModel(filename) {
  return postJson("/api/delete-tts-model", { filename });
}

export async function loadModel(filename, backend = "auto") {
  return postJson("/api/load-model", { filename, backend });
}

export async function loadLlmModel(filename, settings = {}) {
  return postJson("/api/load-llm-model", { filename, settings });
}

export async function unloadModel() {
  return postJson("/api/unload-model", {});
}

export async function unloadLlmModel() {
  return postJson("/api/unload-llm-model", {});
}

export async function generateImage(params) {
  return postJson("/api/generate", params);
}

export async function getGenerationProgress() {
  return fetchJson("/api/generation-progress");
}

export async function cancelGeneration() {
  return postJson("/api/cancel-generation", {});
}

export async function listGeneratedOutputs() {
  return fetchJson("/api/outputs");
}

export async function listLlmConversations() {
  return fetchJson("/api/llm-conversations");
}

export async function saveLlmConversation(conversation) {
  return postJson("/api/save-llm-conversation", { conversation });
}

export async function deleteLlmConversation(id) {
  return postJson("/api/delete-llm-conversation", { id });
}

export async function listSpeechTranscriptions() {
  return fetchJson("/api/speech-transcriptions");
}

export async function deleteSpeechTranscription(id) {
  return postJson("/api/delete-speech-transcription", { id });
}

export async function listTtsOutputs() {
  return fetchJson("/api/tts-outputs");
}

export async function deleteTtsOutput(id) {
  return postJson("/api/delete-tts-output", { id });
}

export async function stopServer() {
  return postJson("/api/stop-server", {});
}

export async function importModelFile(file, kind = "image", onProgress = null) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    let abortedByUser = false;

    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable && onProgress) {
        onProgress(Math.round((event.loaded / event.total) * 100));
      }
    });

    xhr.addEventListener("load", () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          resolve(JSON.parse(xhr.responseText));
        } catch (_) {
          resolve({ ok: true });
        }
      } else {
        try {
          const err = JSON.parse(xhr.responseText);
          reject(new Error(err.error || `Upload failed: HTTP ${xhr.status}`));
        } catch (_) {
          reject(new Error(`Upload failed: HTTP ${xhr.status}`));
        }
      }
    });

    xhr.addEventListener("error", () => reject(new Error("Network error during file import.")));
    xhr.addEventListener("abort", () => reject(new DOMException(abortedByUser ? "Import cancelled by user." : "Import aborted.", "AbortError")));

    const formData = new FormData();
    formData.append("file", file);
    formData.append("kind", kind);

    xhr.open("POST", `${API_BASE}/api/import-model`);
    xhr.send(formData);
  });
}
