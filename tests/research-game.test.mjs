import assert from "node:assert/strict";
import test from "node:test";

import {
    decodeBingRedirect,
    parseBingResults,
    extractFeatureLines,
    compileFeatureMap,
    resolveUniverseId,
    fetchGameNameFromPlace,
} from "../dist/tools/impl/research/research-game.js";

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

function textResponse(body) {
    return { ok: true, status: 200, text: async () => body };
}

test("decodeBingRedirect decodes URL-safe base64 redirect links", () => {
    // aHR0cHM6Ly93d3cuZXhhbXBsZS5jb20vd2lraQ == https://www.example.com/wiki
    const href = "https://www.bing.com/ck/a?!&&p=abc&u=a1aHR0cHM6Ly93d3cuZXhhbXBsZS5jb20vd2lraQ&ntb=1";
    assert.equal(decodeBingRedirect(href), "https://www.example.com/wiki");
});

test("decodeBingRedirect rejects garbage and non-http payloads", () => {
    assert.equal(decodeBingRedirect("https://www.bing.com/ck/a?u=a1AAAA"), null);
    assert.equal(decodeBingRedirect("https://www.bing.com/search?q=1"), null);
    assert.equal(decodeBingRedirect(""), null);
});

test("parseBingResults extracts titles, decoded urls, hosts and snippets", () => {
    // Redirect target: https://brookhaven.fandom.com/wiki/Brookhaven (base64url, unpadded)
    const html = [
        '<ol id="b_results">',
        '<li class="b_algo" iid="SERP.1">',
        '<h2><a target="_blank" href="https://www.bing.com/ck/a?!&&p=abc&u=a1aHR0cHM6Ly9icm9va2hhdmVuLmZhbmRvbS5jb20vd2lraS9Ccm9va2hhdmVu&ntb=1"><strong>Brookhaven</strong> | Wiki</a></h2>',
        '<div class="b_caption"><p class="b_lineclamp2">A roleplay game about houses and cars.</p></div>',
        "</li>",
        '<li class="b_algo" iid="SERP.2">',
        "<h2><a href=\"https://example.org/guide\">Guide</a></h2>",
        "</li>",
        "</ol>",
    ].join("");
    const results = parseBingResults(html);
    assert.equal(results.length, 2);
    assert.equal(results[0].url, "https://brookhaven.fandom.com/wiki/Brookhaven");
    assert.equal(results[0].host, "brookhaven.fandom.com");
    assert.equal(results[0].title, "Brookhaven | Wiki");
    assert.equal(results[0].snippet, "A roleplay game about houses and cars.");
    assert.equal(results[1].url, "https://example.org/guide");
});

test("extractFeatureLines keeps list items and sentences, drops headings", () => {
    const extract = [
        "== Gameplay ==",
        "Brookhaven is a roleplaying game.",
        "- Buy and customize houses",
        "* Drive vehicles around the city",
        "short",
        "- Buy and customize houses",
    ].join("\n");
    const features = extractFeatureLines(extract);
    assert.deepEqual(features, [
        "Brookhaven is a roleplaying game.",
        "Buy and customize houses",
        "Drive vehicles around the city",
    ]);
});

test("compileFeatureMap renders sources, wiki features and next steps", () => {
    const map = compileFeatureMap({
        gameName: "Brookhaven RP",
        placeId: 4924922222,
        universeId: 1686885941,
        searchResults: [
            { title: "Guide", url: "https://example.org/guide", host: "example.org", snippet: "How to play." },
            { title: "Wiki", url: "https://brookhaven.fandom.com/wiki/Brookhaven", host: "brookhaven.fandom.com", snippet: "" },
        ],
        wikiHost: "brookhaven.fandom.com",
        wikiPages: [
            { title: "Gameplay", extract: "- Buy houses\n- Drive cars" },
        ],
    });
    assert.match(map, /# Feature Map: Brookhaven RP/);
    assert.match(map, /place 4924922222/);
    assert.match(map, /universe 1686885941/);
    assert.match(map, /### Gameplay/);
    assert.match(map, /- Buy houses/);
    assert.match(map, /\[Guide\]\(https:\/\/example\.org\/guide\)/);
    // Fandom results are covered by the wiki section, not duplicated as web sources.
    assert.ok(!map.includes("- [Wiki](https://brookhaven.fandom.com/wiki/Brookhaven)"));
    assert.match(map, /find-game-systems/);
});

test("resolveUniverseId parses the Roblox universes API", async (t) => {
    const calls = stubFetch(t, () => textResponse(JSON.stringify({ universeId: 1686885941 })));
    const universeId = await resolveUniverseId(4924922222);
    assert.equal(universeId, 1686885941);
    assert.match(calls[0].url, /universes\/v1\/places\/4924922222\/universe/);
});

test("resolveUniverseId returns null on failure", async (t) => {
    stubFetch(t, () => ({ ok: false, status: 404, text: async () => "" }));
    assert.equal(await resolveUniverseId(1), null);
});

test("fetchGameNameFromPlace reads the og:title from the game page", async (t) => {
    stubFetch(t, () => textResponse('<html><head><meta property="og:title" content="Brookhaven RP" /></head></html>'));
    assert.equal(await fetchGameNameFromPlace(4924922222), "Brookhaven RP");
});
