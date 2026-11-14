import assert from "node:assert/strict";
import test from "node:test";

import {
    parseDuckDuckGoResults,
    parseMojeekResults,
    filterRelevantResults,
    filterScriptsForGame,
    scriptBloxSearch,
    fetchUniverseInfo,
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

test("parseDuckDuckGoResults extracts direct and uddg-redirected results", () => {
    const html = [
        '<div class="result results_links results_links_deep web-result">',
        '<h2 class="result__title">',
        '<a rel="nofollow" class="result__a" href="https://brookhaven.fandom.com/wiki/Brookhaven">Brookhaven | Wiki</a>',
        "</h2>",
        '<a class="result__snippet" href="https://brookhaven.fandom.com/wiki/Brookhaven">A roleplay game about houses and cars.</a>',
        "</div>",
        '<div class="result results_links results_links_deep web-result">',
        '<h2 class="result__title">',
        '<a rel="nofollow" class="result__a" href="https://duckduckgo.com/l/?uddg=https%3A%2F%2Fexample.org%2Fguide&amp;rut=abc">Guide</a>',
        "</h2>",
        "</div>",
    ].join("");
    const results = parseDuckDuckGoResults(html);
    assert.equal(results.length, 2);
    assert.equal(results[0].url, "https://brookhaven.fandom.com/wiki/Brookhaven");
    assert.equal(results[0].host, "brookhaven.fandom.com");
    assert.equal(results[0].title, "Brookhaven | Wiki");
    assert.equal(results[0].snippet, "A roleplay game about houses and cars.");
    assert.equal(results[1].url, "https://example.org/guide");
});

test("parseDuckDuckGoResults rejects non-http and garbage hrefs", () => {
    const html = [
        '<div class="result"><a class="result__a" href="javascript:alert(1)">Bad</a></div>',
        '<div class="result"><a class="result__a" href="https://duckduckgo.com/l/?uddg=not-a-url">Bad uddg</a></div>',
    ].join("");
    assert.deepEqual(parseDuckDuckGoResults(html), []);
});

test("parseMojeekResults extracts titles, urls and snippets", () => {
    const html = [
        "<ul>",
        '<li><a class="ob" href="https://example.com/"></a>',
        '<a class="title" href="https://example.com/brookhaven"><h2>Brookhaven Guide</h2></a>',
        '<p class="s">How to play Brookhaven with houses and cars.</p>',
        "</li>",
        "</ul>",
    ].join("");
    const results = parseMojeekResults(html);
    assert.equal(results.length, 1);
    assert.equal(results[0].url, "https://example.com/brookhaven");
    assert.equal(results[0].title, "Brookhaven Guide");
    assert.equal(results[0].snippet, "How to play Brookhaven with houses and cars.");
});

test("webSearch falls through providers until one returns results", async (t) => {
    const { webSearch } = await import("../dist/tools/impl/research/research-game.js");
    // Bing returns an empty SERP (blocked), DuckDuckGo returns a result.
    let call = 0;
    stubFetch(t, () => {
        call += 1;
        if (call === 1)
            return textResponse("<html>no results</html>");
        return textResponse(
            '<div class="result"><a class="result__a" href="https://example.org/guide">Guide</a></div>',
        );
    });
    const results = await webSearch("brookhaven roblox");
    assert.equal(results.length, 1);
    assert.equal(results[0].url, "https://example.org/guide");
});

test("webSearch returns empty when every provider fails", async (t) => {
    const { webSearch } = await import("../dist/tools/impl/research/research-game.js");
    stubFetch(t, () => ({ ok: false, status: 403, text: async () => "" }));
    assert.deepEqual(await webSearch("anything"), []);
});

test("filterRelevantResults drops generic matches for multi-token game names", () => {
    const results = [
        { title: "Volleyball - Wikipedia", url: "https://en.wikipedia.org/wiki/Volleyball", host: "en.wikipedia.org", snippet: "Volleyball is a team sport." },
        { title: "Volleyball Legends Wiki", url: "https://volleyball-legends.fandom.com/wiki/Main", host: "volleyball-legends.fandom.com", snippet: "Roblox volleyball legends guide" },
    ];
    const kept = filterRelevantResults(results, "[UPD] Volleyball Legends: Starter");
    assert.equal(kept.length, 1);
    assert.equal(kept[0].host, "volleyball-legends.fandom.com");
});

test("filterRelevantResults requires a Roblox hint for single-token names", () => {
    const results = [
        { title: "Volleyball World", url: "https://en.volleyballworld.com/", host: "en.volleyballworld.com", snippet: "Live stream professional volleyball." },
        { title: "Volleyball Roblox Game Guide", url: "https://example.org/guide", host: "example.org", snippet: "Roblox volleyball game tips" },
    ];
    const kept = filterRelevantResults(results, "Volleyball");
    assert.equal(kept.length, 1);
    assert.equal(kept[0].title, "Volleyball Roblox Game Guide");
});

test("filterScriptsForGame keeps game scripts and drops universal hubs", () => {
    const scripts = [
        { title: "Axon Hub | 100+ Games", slug: "hub", gameName: "Script hub", gameId: -1, views: 301069, verified: true, isPatched: false },
        { title: "AUTO RECEIVE, LAND PREDICTOR, PERFECT SERVE", slug: "arcane-vb", gameName: "[UPD] Volleyball Legends", gameId: 73956553001240, views: 405, verified: false, isPatched: false },
        { title: "OP Ball Hitbox Expander", slug: "hitbox", gameName: "[UPD] Volleyball Legends", gameId: 73956553001240, views: 5050, verified: false, isPatched: true },
    ];
    const kept = filterScriptsForGame(scripts, { gameName: "Volleyball Legends", rootPlaceId: 73956553001240 });
    assert.equal(kept.length, 2);
    assert.equal(kept[0].slug, "arcane-vb"); // non-patched sorts ahead of patched
    assert.ok(!kept.some((s) => s.gameId === -1));
});

test("filterScriptsForGame falls back to name-token matching without a root place", () => {
    const scripts = [
        { title: "Auto Farm for Brookhaven", slug: "bh-farm", gameName: "Brookhaven RP", gameId: 123, views: 10, verified: false, isPatched: false },
        { title: "Some Other Game Script", slug: "other", gameName: "Adopt Me", gameId: 456, views: 10, verified: false, isPatched: false },
    ];
    const kept = filterScriptsForGame(scripts, { gameName: "Brookhaven" });
    assert.equal(kept.length, 1);
    assert.equal(kept[0].slug, "bh-farm");
});

test("scriptBloxSearch parses the ScriptBlox API response", async (t) => {
    const calls = stubFetch(t, () => textResponse(JSON.stringify({
        result: {
            scripts: [
                {
                    title: "AUTO RECEIVE, LAND PREDICTOR",
                    slug: "Arcane-Volleyball-1",
                    game: { name: "[UPD] Volleyball Legends", gameId: 73956553001240 },
                    views: 405,
                    verified: true,
                    isPatched: false,
                },
                { title: "", slug: "broken" },
            ],
        },
    })));
    const scripts = await scriptBloxSearch("volleyball legends");
    assert.equal(scripts.length, 1);
    assert.equal(scripts[0].title, "AUTO RECEIVE, LAND PREDICTOR");
    assert.equal(scripts[0].gameId, 73956553001240);
    assert.equal(scripts[0].verified, true);
    assert.match(calls[0].url, /scriptblox\.com\/api\/script\/search/);
});

test("fetchUniverseInfo reads the canonical name and root place", async (t) => {
    stubFetch(t, () => textResponse(JSON.stringify({ data: [{ name: "[UPD] Volleyball Legends", rootPlaceId: 73956553001240 }] })));
    const info = await fetchUniverseInfo(6931042565);
    assert.deepEqual(info, { name: "[UPD] Volleyball Legends", rootPlaceId: 73956553001240 });
});

test("compileFeatureMap includes the ScriptBlox section", () => {
    const map = compileFeatureMap({
        gameName: "Volleyball Legends",
        placeId: 74691681039273,
        searchResults: [],
        wikiPages: [],
        scripts: [
            { title: "AUTO RECEIVE, LAND PREDICTOR, PERFECT SERVE", slug: "Arcane-Volleyball-1", gameName: "[UPD] Volleyball Legends", gameId: 73956553001240, views: 405, verified: true, isPatched: false },
        ],
    });
    assert.match(map, /## Community script features \(ScriptBlox\)/);
    assert.match(map, /AUTO RECEIVE, LAND PREDICTOR/);
    assert.match(map, /https:\/\/scriptblox\.com\/script\/Arcane-Volleyball-1/);
});
