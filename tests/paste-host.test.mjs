import assert from "node:assert/strict";
import test from "node:test";

import {
    checkPasteHostHealth,
    exportImageToPasteVoid,
    exportTextToPasteVoid,
    PASTE_VOID_IMAGE_ENDPOINT,
    PASTE_VOID_TEXT_ENDPOINT,
    PASTE_VOID_HEALTH_ENDPOINT,
} from "../dist/shared/paste-void.js";

/** Minimal Response stand-in — the paste-void helper only reads status and text(). */
function jsonResponse(status, payload) {
    return { ok: status >= 200 && status < 300, status, text: async () => JSON.stringify(payload) };
}

function textResponse(status, body) {
    return { ok: status >= 200 && status < 300, status, text: async () => body };
}

/** Install a fetch stub; returns a call log. Restored automatically after the test. */
function stubFetch(t, handler) {
    const originalFetch = globalThis.fetch;
    const calls = [];
    globalThis.fetch = async (url, init) => {
        calls.push({ url, init });
        return handler(calls.length, url, init);
    };
    t.after(() => {
        globalThis.fetch = originalFetch;
    });
    return calls;
}

test("paste-void text export happy path returns the rawUrl", async (t) => {
    const calls = stubFetch(t, () => jsonResponse(200, { rawUrl: "https://pastevoid.base44.app/raw/happy" }));

    const result = await exportTextToPasteVoid("print('hi')", { language: "lua", title: "mcp-execute" });

    assert.equal(result.ok, true);
    assert.equal(result.url, "https://pastevoid.base44.app/raw/happy");
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, PASTE_VOID_TEXT_ENDPOINT);
    assert.equal(calls[0].init.method, "POST");
    const body = JSON.parse(calls[0].init.body);
    assert.equal(body.content, "print('hi')");
    assert.equal(body.language, "lua");
    assert.equal(body.title, "mcp-execute");
});

test("paste-void text export retry works with a plain title string", async (t) => {
    stubFetch(t, () => jsonResponse(200, { rawUrl: "https://pastevoid.base44.app/raw/legacy-title" }));

    const result = await exportTextToPasteVoid("legacy payload", "legacy-title");

    assert.equal(result.ok, true);
    assert.equal(result.url, "https://pastevoid.base44.app/raw/legacy-title");
});

test("paste-void text export retries exactly once on HTTP 429 and then succeeds", async (t) => {
    const calls = stubFetch(t, (attempt) =>
        attempt === 1
            ? jsonResponse(429, { error: "rate limited" })
            : jsonResponse(200, { rawUrl: "https://pastevoid.base44.app/raw/after-retry" }));

    const startedAt = Date.now();
    const result = await exportTextToPasteVoid("rate limited payload");
    const elapsed = Date.now() - startedAt;

    assert.equal(result.ok, true);
    assert.equal(result.url, "https://pastevoid.base44.app/raw/after-retry");
    assert.equal(calls.length, 2, "429 must trigger exactly one retry");
    assert.ok(elapsed >= 2000, `retry must wait ~2.5s before retrying (waited ${elapsed}ms)`);
});

test("paste-void text export retries once on a network error and then succeeds", async (t) => {
    const calls = stubFetch(t, (attempt) => {
        if (attempt === 1)
            throw new Error("ECONNRESET");
        return jsonResponse(200, { rawUrl: "https://pastevoid.base44.app/raw/network-retry" });
    });

    const result = await exportTextToPasteVoid("network flaky payload");

    assert.equal(result.ok, true);
    assert.equal(result.url, "https://pastevoid.base44.app/raw/network-retry");
    assert.equal(calls.length, 2, "a network error must trigger exactly one retry");
});

test("paste-void text export does NOT retry on a 400 validation error", async (t) => {
    const calls = stubFetch(t, () => jsonResponse(400, { error: "content is required" }));

    const result = await exportTextToPasteVoid("invalid payload");

    assert.equal(result.ok, false);
    assert.equal(calls.length, 1, "validation errors must not be retried");
    assert.match(result.error, /400/);
    assert.match(result.error, /pastevoid\.base44\.app/);
});

test("paste-void text export reports the host and status after a failed 429 retry", async (t) => {
    stubFetch(t, () => jsonResponse(429, { error: "rate limited" }));

    const result = await exportTextToPasteVoid("still rate limited");

    assert.equal(result.ok, false);
    assert.match(result.error, /429/);
    assert.match(result.error, /pastevoid\.base44\.app/);
    assert.match(result.error, /retried once/);
});

test("paste-void image export accepts every URL field variant", async (t) => {
    const variants = [
        ["rawUrl", "https://pastevoid.base44.app/img/raw"],
        ["url", "https://pastevoid.base44.app/img/url"],
        ["link", "https://pastevoid.base44.app/img/link"],
        ["imageUrl", "https://pastevoid.base44.app/img/imageUrl"],
        ["directUrl", "https://pastevoid.base44.app/img/directUrl"],
    ];

    for (const [key, url] of variants) {
        const calls = stubFetch(t, () => jsonResponse(200, { [key]: url }));

        const result = await exportImageToPasteVoid("aGVsbG8=", "image/png");

        assert.equal(result.ok, true, `${key} variant must resolve a URL`);
        assert.equal(result.url, url);
        assert.equal(calls.length, 1);
        assert.equal(calls[0].url, PASTE_VOID_IMAGE_ENDPOINT);
        const body = JSON.parse(calls[0].init.body);
        assert.equal(body.image, "data:image/png;base64,aGVsbG8=");
    }
});

test("paste-void image export rejects empty base64 without uploading", async (t) => {
    const calls = stubFetch(t, () => jsonResponse(200, { rawUrl: "https://pastevoid.base44.app/img/never" }));

    const result = await exportImageToPasteVoid("", "image/png");

    assert.equal(result.ok, false);
    assert.equal(calls.length, 0, "empty image content must not hit the network");
});

test("paste-void health check parses ok and uptime", async (t) => {
    const calls = stubFetch(t, () => jsonResponse(200, { ok: true, uptime: 123.5 }));

    const result = await checkPasteHostHealth();

    assert.equal(result.ok, true);
    assert.equal(result.uptime, 123.5);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, PASTE_VOID_HEALTH_ENDPOINT);
    assert.equal(calls[0].init.method, "GET");
});

test("paste-void health check reports non-ok responses with the host and status", async (t) => {
    stubFetch(t, () => textResponse(503, "unavailable"));

    const result = await checkPasteHostHealth();

    assert.equal(result.ok, false);
    assert.match(result.error, /503/);
    assert.match(result.error, /pastevoid\.base44\.app/);
});
