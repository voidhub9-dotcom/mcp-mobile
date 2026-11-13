/**
 * paste-void export helper.
 *
 * Single source of truth for uploading to the paste-void service
 * (https://pastevoid.lovable.app). Text pastes (decompiled sources,
 * disassemblies, logs) and images both come back as raw URLs.
 *
 * Behavior notes:
 * - Requests keep the endpoints, body shapes, and response parsing that are
 *   live-verified against the real service. Do not change them casually.
 * - Uploads retry exactly once (after ~2.5s) on HTTP 429 / 5xx / network
 *   errors, so the 30-writes/min/IP limit does not cause spurious failures.
 *   Validation errors (other 4xx) are never retried.
 */

export const PASTE_VOID_HOST = "https://pastevoid.lovable.app";
export const PASTE_VOID_HOST_NAME = "pastevoid.lovable.app";
export const PASTE_VOID_TEXT_ENDPOINT = `${PASTE_VOID_HOST}/api/paste`;
export const PASTE_VOID_IMAGE_ENDPOINT = `${PASTE_VOID_HOST}/api/upload-image`;
export const PASTE_VOID_HEALTH_ENDPOINT = `${PASTE_VOID_HOST}/api/health`;

export interface PasteVoidResult {
    ok: boolean;
    url?: string;
    error?: string;
}

export interface PasteVoidHealthResult {
    ok: boolean;
    uptime?: number;
    error?: string;
}

export interface PasteVoidTextOptions {
    title?: string;
    language?: string;
}

const PASTE_TIMEOUT_MS = 15000;
const HEALTH_TIMEOUT_MS = 5000;
const MAX_PASTE_CHARS = 2_000_000;
const RETRY_DELAY_MS = 2500;

/** Upload a text paste and return its raw URL. */
export async function exportTextToPasteVoid(
    content: string,
    options?: string | PasteVoidTextOptions,
): Promise<PasteVoidResult> {
    if (!content.trim())
        return { ok: false, error: "Refusing to paste empty content." };
    if (content.length > MAX_PASTE_CHARS)
        return { ok: false, error: `Content is too large for paste-void (${content.length} chars, max ${MAX_PASTE_CHARS}).` };

    // Backward compatibility: the second argument used to be a plain title string.
    const resolved: PasteVoidTextOptions = typeof options === "string" ? { title: options } : (options ?? {});
    const body = JSON.stringify({
        content,
        ...(resolved.language ? { language: resolved.language } : {}),
        ...(resolved.title ? { title: resolved.title } : {}),
    });

    const result = await postPasteWithRetry(PASTE_VOID_TEXT_ENDPOINT, body);
    if (!result.ok)
        return result;
    const url = extractUrl(result.parsed, ["rawUrl", "url", "link", "pasteUrl"]);
    if (!url)
        return { ok: false, error: `paste-void (${PASTE_VOID_HOST_NAME}) response did not include a URL: ${result.text.slice(0, 200)}` };
    return { ok: true, url };
}

/** Upload a base64 image and return its hosted URL. */
export async function exportImageToPasteVoid(base64: string, mimeType: string): Promise<PasteVoidResult> {
    if (!base64)
        return { ok: false, error: "Refusing to paste empty image content." };
    const body = JSON.stringify({ image: `data:${mimeType};base64,${base64}` });

    const result = await postPasteWithRetry(PASTE_VOID_IMAGE_ENDPOINT, body);
    if (!result.ok)
        return result;
    const url = extractUrl(result.parsed, ["rawUrl", "url", "link", "imageUrl", "directUrl"]);
    if (!url)
        return { ok: false, error: `paste-void (${PASTE_VOID_HOST_NAME}) response did not include a URL: ${result.text.slice(0, 200)}` };
    return { ok: true, url };
}

/** Check the paste-void health endpoint (GET /api/health, 5s timeout). */
export async function checkPasteHostHealth(): Promise<PasteVoidHealthResult> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), HEALTH_TIMEOUT_MS);
    try {
        const response = await fetch(PASTE_VOID_HEALTH_ENDPOINT, {
            method: "GET",
            headers: { Accept: "application/json" },
            signal: controller.signal,
        });
        const text = await response.text();
        if (!response.ok)
            return { ok: false, error: `paste-void (${PASTE_VOID_HOST_NAME}) health check returned HTTP ${response.status}: ${text.slice(0, 200)}` };
        const parsed = safeParseJson(text);
        const record = parsed && typeof parsed === "object" ? (parsed as Record<string, unknown>) : {};
        const ok = record.ok === true;
        const uptime = typeof record.uptime === "number" ? record.uptime : undefined;
        if (!ok)
            return { ok: false, error: `paste-void (${PASTE_VOID_HOST_NAME}) health check reported ok=${String(record.ok)}.` };
        return { ok: true, uptime };
    }
    catch (error) {
        const aborted = error instanceof Error && error.name === "AbortError";
        return {
            ok: false,
            error: aborted
                ? `paste-void (${PASTE_VOID_HOST_NAME}) health check timed out after ${HEALTH_TIMEOUT_MS / 1000}s.`
                : `paste-void (${PASTE_VOID_HOST_NAME}) health check failed: ${error instanceof Error ? error.message : String(error)}`,
        };
    }
    finally {
        clearTimeout(timer);
    }
}

interface PostSuccess {
    ok: true;
    status: number;
    text: string;
    parsed: unknown;
}

interface PostFailure {
    ok: false;
    error: string;
}

/**
 * POST to a paste-void endpoint with a single automatic retry on HTTP 429,
 * 5xx, or network errors. Validation errors (other 4xx) fail immediately.
 */
async function postPasteWithRetry(endpoint: string, body: string): Promise<PostSuccess | PostFailure> {
    let lastError: string | undefined;

    for (let attempt = 1; attempt <= 2; attempt++) {
        if (attempt > 1)
            await sleep(RETRY_DELAY_MS);

        let status: number;
        let text: string;
        try {
            const fetched = await fetchOnce(endpoint, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body,
            }, PASTE_TIMEOUT_MS);
            status = fetched.status;
            text = fetched.text;
        }
        catch (error) {
            const aborted = error instanceof Error && error.name === "AbortError";
            lastError = aborted
                ? `paste-void (${PASTE_VOID_HOST_NAME}) upload timed out after ${PASTE_TIMEOUT_MS / 1000}s.`
                : `paste-void (${PASTE_VOID_HOST_NAME}) upload failed: ${error instanceof Error ? error.message : String(error)}`;
            continue; // network error -> retry once
        }

        if (status >= 200 && status < 300) {
            return { ok: true, status, text, parsed: safeParseJson(text) };
        }

        lastError = `paste-void (${PASTE_VOID_HOST_NAME}) returned HTTP ${status}: ${text.slice(0, 200)}`;
        // Only transient failures (rate limit / server errors) are retried.
        if (status !== 429 && status < 500)
            return { ok: false, error: lastError };
    }

    return { ok: false, error: `${lastError ?? "unknown error"} (retried once after ${RETRY_DELAY_MS / 1000}s)` };
}

async function fetchOnce(url: string, init: RequestInit, timeoutMs: number): Promise<{ status: number; text: string }> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const response = await fetch(url, { ...init, signal: controller.signal });
        const text = await response.text();
        return { status: response.status, text };
    }
    finally {
        clearTimeout(timer);
    }
}

function sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

function safeParseJson(text: string): unknown {
    try {
        return text ? JSON.parse(text) : {};
    }
    catch {
        return undefined;
    }
}

function extractUrl(value: unknown, keys: string[]): string | undefined {
    if (!value || typeof value !== "object")
        return undefined;
    const record = value as Record<string, unknown>;
    for (const key of keys) {
        const candidate = record[key];
        if (typeof candidate === "string" && /^https?:\/\//.test(candidate))
            return candidate;
    }
    return undefined;
}
