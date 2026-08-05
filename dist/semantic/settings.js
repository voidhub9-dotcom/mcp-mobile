import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { withFileTransaction, writeJsonAtomic } from "../shared/atomic-json.js";
export const SEMANTIC_CONFIG_DIR = path.join(os.homedir(), ".roblox-mcp");
export const SEMANTIC_SETTINGS_PATH = path.join(SEMANTIC_CONFIG_DIR, "semantic-search.json");
export const DEFAULT_SEMANTIC_SETTINGS = {
    enabled: true,
    provider: "openai",
    openaiApiKey: "",
    openaiBaseUrl: "https://api.openai.com/v1",
    openaiModel: "text-embedding-3-small",
    ollamaBaseUrl: "http://localhost:11434",
    ollamaModel: "embeddinggemma",
    saveEmbeddingsToDisk: false,
};
function isObject(value) {
    return typeof value === "object" && value !== null;
}
function normalizeProvider(value, fallback) {
    return value === "openai" || value === "ollama" ? value : fallback;
}
function normalizeString(value, fallback) {
    return typeof value === "string" ? value.trim() : fallback;
}
export function normalizeOllamaBaseUrl(value, fallback) {
    const raw = normalizeString(value, fallback);
    if (!raw)
        return fallback;
    const withProtocol = /^https?:\/\//i.test(raw) ? raw : `http://${raw}`;
    let url;
    try {
        url = new URL(withProtocol);
    }
    catch {
        return raw;
    }
    if (!url.port) {
        url.port = "11434";
    }
    return url.toString().replace(/\/+$/, "");
}
export function normalizeOpenAIBaseUrl(value, fallback) {
    const raw = normalizeString(value, fallback);
    if (!raw)
        return fallback;
    const withProtocol = /^https?:\/\//i.test(raw) ? raw : `https://${raw}`;
    try {
        return new URL(withProtocol).toString().replace(/\/+$/, "").replace(/\/embeddings$/i, "");
    }
    catch {
        return raw.replace(/\/+$/, "").replace(/\/embeddings$/i, "");
    }
}
export async function loadSemanticSettings() {
    try {
        const raw = await fs.readFile(SEMANTIC_SETTINGS_PATH, "utf8");
        const parsed = JSON.parse(raw);
        if (!isObject(parsed))
            return { ...DEFAULT_SEMANTIC_SETTINGS };
        return {
            enabled: typeof parsed.enabled === "boolean"
                ? parsed.enabled
                : DEFAULT_SEMANTIC_SETTINGS.enabled,
            provider: normalizeProvider(parsed.provider, DEFAULT_SEMANTIC_SETTINGS.provider),
            openaiApiKey: normalizeString(parsed.openaiApiKey, DEFAULT_SEMANTIC_SETTINGS.openaiApiKey),
            openaiBaseUrl: normalizeOpenAIBaseUrl(parsed.openaiBaseUrl, DEFAULT_SEMANTIC_SETTINGS.openaiBaseUrl),
            openaiModel: normalizeString(parsed.openaiModel, DEFAULT_SEMANTIC_SETTINGS.openaiModel),
            ollamaBaseUrl: normalizeOllamaBaseUrl(parsed.ollamaBaseUrl, DEFAULT_SEMANTIC_SETTINGS.ollamaBaseUrl),
            ollamaModel: normalizeString(parsed.ollamaModel, DEFAULT_SEMANTIC_SETTINGS.ollamaModel),
            saveEmbeddingsToDisk: typeof parsed.saveEmbeddingsToDisk === "boolean"
                ? parsed.saveEmbeddingsToDisk
                : DEFAULT_SEMANTIC_SETTINGS.saveEmbeddingsToDisk,
        };
    }
    catch (error) {
        const code = error.code;
        if (code === "ENOENT")
            return { ...DEFAULT_SEMANTIC_SETTINGS };
        throw error;
    }
}
export async function saveSemanticSettings(input) {
    return withFileTransaction(SEMANTIC_SETTINGS_PATH, async () => {
        const existing = await loadSemanticSettings();
        const next = {
            enabled: typeof input.enabled === "boolean" ? input.enabled : existing.enabled,
            provider: normalizeProvider(input.provider, existing.provider),
            openaiApiKey: typeof input.openaiApiKey === "string" ? input.openaiApiKey.trim() : existing.openaiApiKey,
            openaiBaseUrl: normalizeOpenAIBaseUrl(input.openaiBaseUrl, existing.openaiBaseUrl),
            openaiModel: normalizeString(input.openaiModel, existing.openaiModel),
            ollamaBaseUrl: normalizeOllamaBaseUrl(input.ollamaBaseUrl, existing.ollamaBaseUrl),
            ollamaModel: normalizeString(input.ollamaModel, existing.ollamaModel),
            saveEmbeddingsToDisk: typeof input.saveEmbeddingsToDisk === "boolean"
                ? input.saveEmbeddingsToDisk
                : existing.saveEmbeddingsToDisk,
        };
        await writeJsonAtomic(SEMANTIC_SETTINGS_PATH, next);
        return next;
    });
}
export function toPublicSemanticSettings(settings) {
    const key = settings.openaiApiKey;
    return {
        enabled: settings.enabled,
        provider: settings.provider,
        openaiApiKeySet: key.length > 0,
        openaiApiKeyMasked: key ? `${key.slice(0, 3)}...${key.slice(-4)}` : "",
        openaiBaseUrl: settings.openaiBaseUrl,
        openaiModel: settings.openaiModel,
        ollamaBaseUrl: settings.ollamaBaseUrl,
        ollamaModel: settings.ollamaModel,
        saveEmbeddingsToDisk: settings.saveEmbeddingsToDisk,
    };
}
export function validateSemanticSettings(settings) {
    if (!settings.enabled)
        return "Semantic search is disabled.";
    if (settings.provider === "openai") {
        if (!settings.openaiApiKey)
            return "OpenAI API key is not configured.";
        if (!settings.openaiBaseUrl)
            return "OpenAI-compatible base URL is not configured.";
        if (!settings.openaiModel)
            return "OpenAI embedding model is not configured.";
        return null;
    }
    if (!settings.ollamaBaseUrl)
        return "Ollama base URL is not configured.";
    if (!settings.ollamaModel)
        return "Ollama embedding model is not configured.";
    return null;
}
export function getSemanticProviderModel(settings) {
    return settings.provider === "openai" ? settings.openaiModel : settings.ollamaModel;
}
