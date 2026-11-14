import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { getActiveClientId, resolveTargetClient } from "../../../bridge/handlers/shared/registry.js";
import { toolTextResponse } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";

/**
 * research-game: builds a "feature map" of a Roblox game by browsing public
 * sources — the Roblox game page, Bing web search across multiple sites
 * (wikis, guides, official pages), and Fandom wiki APIs — so the connected
 * AI gets a ready-made list of what there is to do in the game instead of
 * the user having to supply features by hand.
 *
 * All lookups are server-side (plain HTTP, no client required). When a
 * Roblox client is connected, the active client's place is used by default.
 */

interface SearchResult {
    title: string;
    url: string;
    host: string;
    snippet: string;
}

interface WikiPage {
    title: string;
    extract: string;
}

/** A game-specific script listing from ScriptBlox (scriptblox.com). */
export interface ScriptBloxScript {
    id: string;
    title: string;
    slug: string;
    gameName: string;
    gameId: number;
    views: number;
    verified: boolean;
    isPatched: boolean;
    featureLines?: string[];
}

const FETCH_TIMEOUT_MS = 10_000;
const MAX_BING_RESULTS = 8;
const MAX_WIKI_PAGES = 3;
const WIKI_EXTRACT_CHARS = 2500;
const BING_UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36";

/** Fetch a URL as text with a timeout; returns null on any failure. */
async function fetchText(url: string, init: RequestInit = {}, timeoutMs: number = FETCH_TIMEOUT_MS): Promise<string | null> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
        const response = await fetch(url, {
            ...init,
            redirect: "follow",
            signal: controller.signal,
            headers: { "User-Agent": BING_UA, ...(init.headers ?? {}) },
        });
        if (!response.ok)
            return null;
        return await response.text();
    }
    catch {
        return null;
    }
    finally {
        clearTimeout(timer);
    }
}

/** Look up the universeId for a Roblox placeId. Returns null on failure. */
export async function resolveUniverseId(placeId: number): Promise<number | null> {
    const text = await fetchText(`https://apis.roblox.com/universes/v1/places/${placeId}/universe`);
    if (!text)
        return null;
    try {
        const parsed = JSON.parse(text) as { universeId?: unknown };
        return typeof parsed.universeId === "number" ? parsed.universeId : null;
    }
    catch {
        return null;
    }
}

/** Get the universe's canonical game name and root place from the public games API. */
export async function fetchUniverseInfo(universeId: number): Promise<{ name: string; rootPlaceId: number } | null> {
    const text = await fetchText(`https://games.roblox.com/v1/games?universeIds=${universeId}`);
    if (!text)
        return null;
    try {
        const parsed = JSON.parse(text) as { data?: { name?: unknown; rootPlaceId?: unknown }[] };
        const entry = parsed.data?.[0];
        const name = entry?.name;
        const rootPlaceId = entry?.rootPlaceId;
        if (typeof name === "string" && name.trim().length > 0 && typeof rootPlaceId === "number")
            return { name: name.trim(), rootPlaceId };
        return null;
    }
    catch {
        return null;
    }
}

/** Get the game's display name from the public Roblox game page. */
export async function fetchGameNameFromPlace(placeId: number): Promise<string | null> {
    const html = await fetchText(`https://www.roblox.com/games/${placeId}/`);
    if (!html)
        return null;
    const ogTitle = html.match(/<meta[^>]*property="og:title"[^>]*content="([^"]+)"/);
    if (ogTitle?.[1]) {
        const name = decodeHtmlEntities(ogTitle[1]).trim();
        if (name)
            return name;
    }
    const title = html.match(/<title[^>]*>([^<]+)<\/title>/);
    if (title?.[1]) {
        // Page titles look like "Brookhaven RP - Roblox".
        const name = decodeHtmlEntities(title[1]).replace(/\s*-\s*Roblox\s*$/i, "").trim();
        if (name)
            return name;
    }
    return null;
}

/**
 * Decode a Bing redirect link of the form
 * https://www.bing.com/ck/a?...&u=a1aHR0cHM6... — the u parameter is
 * base64(url) with URL-safe alphabet and no padding. Returns null for
 * anything that does not decode to an http(s) URL.
 */
export function decodeBingRedirect(href: string): string | null {
    const match = href.match(/[?&]u=a1([A-Za-z0-9_-]+)/);
    if (!match?.[1])
        return null;
    try {
        const normalized = match[1].replace(/-/g, "+").replace(/_/g, "/");
        const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
        const decoded = Buffer.from(padded, "base64").toString("utf-8");
        return /^https?:\/\//.test(decoded) ? decoded : null;
    }
    catch {
        return null;
    }
}

/** Strip HTML tags, scripts/styles, and collapse whitespace. */
function htmlToText(html: string): string {
    return decodeHtmlEntities(
        html
            .replace(/<(script|style)[\s\S]*?<\/\1>/gi, "")
            .replace(/<[^>]+>/g, " "),
    ).replace(/\s+/g, " ").trim();
}

/** Decode the handful of entities Bing uses in result markup. */
function decodeHtmlEntities(text: string): string {
    // Built from char codes so the entities survive file tooling verbatim.
    const AMP = String.fromCharCode(38);
    const replaceAll = (pattern: string, value: string) => text.split(pattern).join(value);
    text = text.replace(new RegExp(`${AMP}#x([0-9a-f]+);`, "gi"), (_, hex) => safeFromCodePoint(parseInt(hex, 16)));
    text = text.replace(new RegExp(`${AMP}#(\\d+);`, "g"), (_, dec) => safeFromCodePoint(Number(dec)));
    text = replaceAll(`${AMP}amp;`, AMP);
    text = replaceAll(`${AMP}lt;`, "<");
    text = replaceAll(`${AMP}gt;`, ">");
    text = replaceAll(`${AMP}quot;`, "\"");
    text = text.replace(new RegExp(`${AMP}#0?39;`, "g"), "'");
    text = replaceAll(`${AMP}nbsp;`, " ");
    text = text.replace(new RegExp(`${AMP}#0?183;`, "g"), "·");
    return text.replace(new RegExp(`${AMP}#0?8230;`, "g"), "…");
}

/** fromCodePoint that never throws (surrogate/invalid code points stay literal). */
function safeFromCodePoint(codePoint: number): string {
    try {
        return String.fromCodePoint(codePoint);
    }
    catch {
        return "";
    }
}

/** Strip emoji and other non-ASCII that breaks search engines; collapse whitespace. */
function sanitizeForSearch(name: string): string {
    return name
        .replace(/^\s*[\[(][^)\]]{1,12}[\])]\s*/, "") // leading update tags like "[UPD]" or "[2X]"
        .replace(/[^\x20-\x7E]/g, " ")
        .replace(/\s+/g, " ")
        .trim();
}

/**
 * Filter search results down to ones actually about this Roblox game.
 * Search engines relax obscure queries into generic matches (a search for
 * "Volleyball Legends" degrades into pages about the sport), so every kept
 * result must mention the game's distinctive name tokens, and single-token
 * names additionally need a Roblox context hint.
 */
export function filterRelevantResults(results: SearchResult[], gameName: string): SearchResult[] {
    const sanitized = sanitizeForSearch(gameName);
    const mainName = (sanitized.split(/[:·|]/)[0] || sanitized).trim();
    const tokens = [...new Set(mainName.toLowerCase().split(/[^a-z0-9]+/).filter((t) => t.length > 3))];
    const matchesTokens = (result: SearchResult) => {
        const haystack = `${result.title} ${result.snippet} ${result.host}`.toLowerCase();
        return tokens.length === 0 || tokens.every((t) => haystack.includes(t));
    };
    const tokenMatches = results.filter(matchesTokens);
    if (tokens.length > 1)
        return tokenMatches;
    // A single distinctive token (or none) matches far too much generic
    // content — require a Roblox or Fandom context hint to keep a result.
    return tokenMatches.filter((result) =>
        `${result.title} ${result.snippet}`.toLowerCase().includes("roblox")
        || result.host.includes("fandom.com")
        || result.host.includes("roblox"));
}

/**
 * Parse Bing SERP HTML into search results: one entry per
 * <li class="b_algo"> with an <h2><a href=...> title link and a
 * caption paragraph.
 */
export function parseBingResults(html: string): SearchResult[] {
    const results: SearchResult[] = [];
    const blocks = html.split('<li class="b_algo"');
    for (const block of blocks.slice(1)) {
        const link = block.match(/<h2[^>]*><a[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a><\/h2>/);
        if (!link?.[1] || !link[2])
            continue;
        // Bing entity-encodes & as & in hrefs; decode before parsing the redirect.
        const href = decodeHtmlEntities(link[1]);
        const url = decodeBingRedirect(href) ?? (/^https?:\/\//.test(href) ? href : null);
        if (!url)
            continue;
        const caption = block.match(/<p[^>]*class="b_lineclamp[^"]*"[^>]*>([\s\S]*?)<\/p>/);
        const snippet = caption?.[1] ? htmlToText(caption[1]).slice(0, 300) : "";
        const host = safeHost(url);
        results.push({
            title: htmlToText(link[2]).slice(0, 200),
            url,
            host,
            snippet,
        });
        if (results.length >= MAX_BING_RESULTS)
            break;
    }
    return results;
}

/** Run one Bing web search and return parsed results. */
export async function bingSearch(query: string): Promise<SearchResult[]> {
    const html = await fetchText(`https://www.bing.com/search?q=${encodeURIComponent(query)}&count=${MAX_BING_RESULTS}`);
    return html ? parseBingResults(html) : [];
}

/**
 * Parse DuckDuckGo's no-JS HTML endpoint (html.duckduckgo.com/html/).
 * Each result has <a class="result__a" href=...> for the title and
 * <a class="result__snippet" ...> for the caption. Hrefs may be direct
 * URLs or duckduckgo.com/l/?uddg=<encoded> redirects.
 */
export function parseDuckDuckGoResults(html: string): SearchResult[] {
    const results: SearchResult[] = [];
    const blocks = html.split(/class="result\b/).slice(1);
    for (const block of blocks) {
        if (results.length >= MAX_BING_RESULTS)
            break;
        const link = block.match(/<a[^>]*class="result__a"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/);
        if (!link?.[1] || !link[2])
            continue;
        const href = decodeHtmlEntities(link[1]);
        let url: string | null = null;
        const uddg = href.match(/[?&]uddg=([^&]+)/);
        if (uddg?.[1]) {
            try {
                url = decodeURIComponent(uddg[1]);
            }
            catch {
                url = null;
            }
        }
        else if (/^https?:\/\//.test(href)) {
            url = href;
        }
        if (!url || !/^https?:\/\//.test(url))
            continue;
        const snippetMatch = block.match(/<a[^>]*class="result__snippet"[^>]*>([\s\S]*?)<\/a>/);
        const snippet = snippetMatch?.[1] ? htmlToText(snippetMatch[1]).slice(0, 300) : "";
        results.push({
            title: htmlToText(link[2]).slice(0, 200),
            url,
            host: safeHost(url),
            snippet,
        });
    }
    return results;
}

/** Run one DuckDuckGo search via the no-JS HTML endpoint. */
export async function duckDuckGoSearch(query: string): Promise<SearchResult[]> {
    const html = await fetchText(`https://html.duckduckgo.com/html/?q=${encodeURIComponent(query)}`);
    return html ? parseDuckDuckGoResults(html) : [];
}

/**
 * Parse Mojeek result HTML. Each result is an
 * <a class="title" href="..."><h2>title</h2></a> with a <p class="s">
 * snippet nearby.
 */
export function parseMojeekResults(html: string): SearchResult[] {
    const results: SearchResult[] = [];
    const blocks = html.matchAll(/<a[^>]*class="title"[^>]*href="([^"]+)"[^>]*>([\s\S]*?)<\/a>/g);
    for (const match of blocks) {
        if (results.length >= MAX_BING_RESULTS)
            break;
        const href = decodeHtmlEntities(match[1]);
        if (!/^https?:\/\//.test(href))
            continue;
        const titleMatch = match[2].match(/<h2[^>]*>([\s\S]*?)<\/h2>/);
        const title = titleMatch?.[1] ?? match[2];
        // The snippet paragraph follows the title link, outside the <a> tag.
        const after = html.slice((match.index ?? 0) + match[0].length, (match.index ?? 0) + match[0].length + 2000);
        const snippetMatch = after.match(/<p[^>]*class="s"[^>]*>([\s\S]*?)<\/p>/);
        const snippet = snippetMatch?.[1] ? htmlToText(snippetMatch[1]).slice(0, 300) : "";
        results.push({
            title: htmlToText(title).slice(0, 200),
            url: href,
            host: safeHost(href),
            snippet,
        });
    }
    return results;
}

/** Run one Mojeek search (bot-friendly independent index). */
export async function mojeekSearch(query: string): Promise<SearchResult[]> {
    const html = await fetchText(`https://www.mojeek.com/search?q=${encodeURIComponent(query)}`);
    return html ? parseMojeekResults(html) : [];
}

/**
 * Run one web search across providers (Bing, then DuckDuckGo, then Mojeek)
 * and return the first non-empty result set. Search engines routinely block
 * or challenge cloud and residential-phone hosts, so the fallback chain keeps
 * the tool working when any single provider refuses to serve results.
 */
export async function webSearch(query: string): Promise<SearchResult[]> {
    const providers: [string, () => Promise<SearchResult[]>][] = [
        ["bing", () => bingSearch(query)],
        ["duckduckgo", () => duckDuckGoSearch(query)],
        ["mojeek", () => mojeekSearch(query)],
    ];
    for (const [, search] of providers) {
        try {
            const results = await search();
            if (results.length > 0)
                return results;
        }
        catch {
            // provider failed — fall through to the next one
        }
    }
    return [];
}

/**
 * Search ScriptBlox (scriptblox.com) for scripts matching a query. Script
 * titles describe game features directly ("Auto Receive, Land Predictor,
 * Perfect Serve"), which makes them a compact feature map for games that
 * have no wiki or guide coverage.
 */
export async function scriptBloxSearch(query: string, max: number = 25): Promise<ScriptBloxScript[]> {
    const text = await fetchText(`https://scriptblox.com/api/script/search?q=${encodeURIComponent(query)}&max=${max}`);
    if (!text)
        return [];
    try {
        const parsed = JSON.parse(text) as { result?: { scripts?: unknown[] } };
        const scripts = parsed.result?.scripts ?? [];
        const out: ScriptBloxScript[] = [];
        for (const entry of scripts) {
            if (!entry || typeof entry !== "object")
                continue;
            const script = entry as Record<string, unknown>;
            const title = typeof script.title === "string" ? script.title : "";
            const slug = typeof script.slug === "string" ? script.slug : "";
            const id = typeof script._id === "string" ? script._id : "";
            if (!title || !slug || !id)
                continue;
            const game = (typeof script.game === "object" && script.game !== null ? script.game : {}) as Record<string, unknown>;
            out.push({
                id,
                title: title.slice(0, 200),
                slug,
                gameName: typeof game.name === "string" ? game.name : "",
                gameId: typeof game.gameId === "number" ? game.gameId : -1,
                views: typeof script.views === "number" ? script.views : 0,
                verified: script.verified === true,
                isPatched: script.isPatched === true,
            });
        }
        return out;
    }
    catch {
        return [];
    }
}

/**
 * Fetch a single script's posted feature list from the ScriptBlox detail API.
 * Posts describe their features as section headers plus "- " bullet lines,
 * e.g. "Auto Play\n- Auto Receive\n- Auto Set". Returns the cleaned lines.
 */
export async function fetchScriptBloxFeatures(scriptId: string): Promise<string[]> {
    const text = await fetchText(`https://scriptblox.com/api/script/${encodeURIComponent(scriptId)}`);
    if (!text)
        return [];
    try {
        const parsed = JSON.parse(text) as { script?: { features?: unknown } };
        const features = parsed.script?.features;
        if (typeof features !== "string" || features.trim().length === 0)
            return [];
        return features
            .split(/\r?\n/)
            .map((line) => line.trim())
            .filter((line) => line.length > 1 && line.length <= 200)
            .slice(0, 20);
    }
    catch {
        return [];
    }
}

/**
 * Keep only scripts that target this specific game: either an exact root
 * place match on ScriptBlox's game entry, or a full name-token match.
 * Universal hub scripts (gameId -1) are always dropped.
 */
export function filterScriptsForGame(
    scripts: ScriptBloxScript[],
    input: { gameName: string; rootPlaceId?: number | null },
): ScriptBloxScript[] {
    const sanitized = sanitizeForSearch(input.gameName);
    const mainName = (sanitized.split(/[:·|]/)[0] || sanitized).trim();
    const tokens = [...new Set(mainName.toLowerCase().split(/[^a-z0-9]+/).filter((t) => t.length > 3))];
    const matches = scripts.filter((script) => {
        if (script.gameId <= 0)
            return false;
        if (input.rootPlaceId && script.gameId === input.rootPlaceId)
            return true;
        if (tokens.length === 0)
            return false;
        const haystack = `${script.title} ${script.gameName}`.toLowerCase();
        return tokens.every((t) => haystack.includes(t));
    });
    // Most-viewed first, patched scripts last.
    matches.sort((a, b) => (a.isPatched === b.isPatched ? b.views - a.views : a.isPatched ? 1 : -1));
    return matches;
}

function safeHost(url: string): string {
    try {
        return new URL(url).host.toLowerCase();
    }
    catch {
        return "";
    }
}

/** Search a Fandom wiki via its MediaWiki API for pages matching a query. */
export async function fandomWikiSearch(host: string, query: string): Promise<{ title: string; pageid: number }[]> {
    const url = `https://${host}/api.php?action=query&list=search&format=json&srlimit=8&srsearch=${encodeURIComponent(query)}`;
    const text = await fetchText(url);
    if (!text)
        return [];
    try {
        const parsed = JSON.parse(text) as { query?: { search?: { title?: unknown; pageid?: unknown }[] } };
        return (parsed.query?.search ?? [])
            .filter((entry) => typeof entry.title === "string" && typeof entry.pageid === "number")
            .map((entry) => ({ title: entry.title as string, pageid: entry.pageid as number }));
    }
    catch {
        return [];
    }
}

/** Fetch plain-text extracts for wiki pages via the MediaWiki API. */
export async function fandomFetchExtracts(host: string, titles: string[]): Promise<WikiPage[]> {
    if (titles.length === 0)
        return [];
    const url = `https://${host}/api.php?action=query&prop=extracts&explaintext=1&exsectionformat=plain&format=json&exlimit=${titles.length}&titles=${encodeURIComponent(titles.slice(0, 20).join("|"))}`;
    const text = await fetchText(url, {}, 15_000);
    if (!text)
        return [];
    try {
        const parsed = JSON.parse(text) as { query?: { pages?: Record<string, { title?: unknown; extract?: unknown }> } };
        const pages = parsed.query?.pages ?? {};
        return Object.values(pages)
            .filter((page) => typeof page.extract === "string" && (page.extract as string).trim().length > 0)
            .map((page) => ({
                title: String(page.title ?? ""),
                extract: (page.extract as string).slice(0, WIKI_EXTRACT_CHARS),
            }));
    }
    catch {
        return [];
    }
}

/**
 * Pull feature-like bullet candidates out of a wiki extract: list items and
 * short lines that describe a game system, item, or mechanic.
 */
export function extractFeatureLines(extract: string, limit: number = 12): string[] {
    const features: string[] = [];
    const seen = new Set<string>();
    const lines = extract.split(/\r?\n/);
    for (let i = 0; i < lines.length && features.length < limit; i++) {
        const line = lines[i].trim();
        // Wiki list items and short descriptive sentences.
        if (!line || line.length < 12 || line.length > 220)
            continue;
        const isListItem = /^[-*•]/.test(line);
        const isHeading = /^(==+|Section)/.test(line);
        if (!isListItem && (isHeading || !/[a-z] [a-z]/.test(line)))
            continue;
        const clean = line.replace(/^[-*•]\s*/, "");
        const key = clean.toLowerCase();
        if (seen.has(key))
            continue;
        seen.add(key);
        features.push(clean);
    }
    return features;
}

/** Compile everything into the feature-map text returned by the tool. */
export function compileFeatureMap(input: {
    gameName: string;
    placeId?: number;
    universeId?: number | null;
    searchResults: SearchResult[];
    wikiHost?: string;
    wikiPages: WikiPage[];
    scripts?: ScriptBloxScript[];
}): string {
    const { gameName, placeId, universeId, searchResults, wikiHost, wikiPages, scripts } = input;
    const lines: string[] = [];
    lines.push(`# Feature Map: ${gameName}`);
    const identifiers = [
        ...(placeId ? [`place ${placeId}`] : []),
        ...(universeId ? [`universe ${universeId}`] : []),
    ].join(" · ");
    if (identifiers)
        lines.push(identifiers);
    lines.push("");
    lines.push("Use this map to plan what to do in the game. Each section cites its source.");
    lines.push("");

    if (scripts && scripts.length > 0) {
        lines.push("## Community script features (ScriptBlox)");
        lines.push("");
        lines.push("Script posts list what the game lets you do — the feature lists below are copied from each post.");
        for (const script of scripts.slice(0, 10)) {
            const flags = [
                script.verified ? "verified" : null,
                script.isPatched ? "patched" : null,
                `${script.views.toLocaleString("en-US")} views`,
            ].filter(Boolean).join(", ");
            lines.push(`- ${script.title} (${flags}) — https://scriptblox.com/script/${script.slug}`);
            for (const feature of script.featureLines ?? [])
                lines.push(`  ${feature.replace(/^[-*•]\s*/, "")}`);
        }
        lines.push("");
    }

    if (wikiPages.length > 0) {
        lines.push("## Wiki feature highlights");
        for (const page of wikiPages) {
            const features = extractFeatureLines(page.extract);
            if (features.length === 0)
                continue;
            lines.push("");
            lines.push(`### ${page.title}`);
            if (wikiHost)
                lines.push(`Source: https://${wikiHost}/wiki/${encodeURIComponent(page.title.replace(/ /g, "_"))}`);
            for (const feature of features)
                lines.push(`- ${feature}`);
        }
        lines.push("");
    }

    if (searchResults.length > 0) {
        lines.push("## Web sources");
        for (const result of searchResults) {
            if (result.host.endsWith("fandom.com"))
                continue; // already covered by the wiki section
            lines.push(`- [${result.title}](${result.url}) — ${result.host}`);
            if (result.snippet)
                lines.push(`  ${result.snippet}`);
        }
        lines.push("");
    }

    lines.push("## Suggested in-game next steps");
    lines.push("- find-game-systems / get-game-guis: enumerate the live systems and menus behind these features");
    lines.push("- decrypt-remote scan: find the remotes that implement them");
    lines.push("- get-ai-script-context: pull the relevant scripts for deeper analysis");
    return lines.join("\n");
}

export default function register(server: McpServer): void {
    server.registerTool("research-game", {
        title: "Research a game's features across the web",
        description: "Builds a feature map of a Roblox game by browsing public sources: the Roblox game page, Bing web search across multiple sites (wikis, guides, official pages), and Fandom wiki APIs. Returns the game's systems, mechanics, items and progression with source links, so you can plan what to do in the game without the user supplying features manually. Uses the active client's game by default; also works without a connected client if placeId or gameName is provided.",
        inputSchema: z.object({
            placeId: z
                .number()
                .describe("Roblox placeId of the game to research. Defaults to the active client's current game.")
                .optional(),
            gameName: z
                .string()
                .describe("Game name to search for. Optional — derived from placeId or the active client when omitted.")
                .optional(),
            maxOutputChars: maxOutputCharsSchema,
        }),
    }, async ({ placeId, gameName, maxOutputChars }) => {
        let resolvedPlaceId = placeId;
        let name = gameName;

        if (resolvedPlaceId === undefined || !name) {
            const target = resolveTargetClient(getActiveClientId());
            if (target) {
                if (resolvedPlaceId === undefined && target.placeId)
                    resolvedPlaceId = target.placeId;
                if (!name && target.placeName)
                    name = target.placeName;
            }
        }
        if (resolvedPlaceId === undefined && !name)
            return toolTextResponse(
                "Provide a placeId or gameName, or connect a Roblox client so the active game can be used.",
                {},
                true,
            );

        let universeId: number | null = null;
        let rootPlaceId: number | null = null;
        if (resolvedPlaceId !== undefined) {
            universeId = await resolveUniverseId(resolvedPlaceId);
            if (universeId !== null) {
                // The universe API gives the canonical game name and the root
                // place — sub-places (e.g. "Some Game: Starter") inherit a
                // name that pollutes searches, so prefer the real game name.
                const universeInfo = await fetchUniverseInfo(universeId);
                if (universeInfo) {
                    rootPlaceId = universeInfo.rootPlaceId;
                    name = universeInfo.name;
                }
            }
            if (!name)
                name = await fetchGameNameFromPlace(resolvedPlaceId) ?? undefined;
        }
        if (!name)
            return toolTextResponse(
                "Could not resolve the game name. Provide gameName explicitly.",
                {},
                true,
            );

        // Community scripts describe the game's features directly. Search
        // ScriptBlox for this game, keep only scripts that target it, and
        // pull each post's full feature list from its detail page.
        const scriptSearchName = sanitizeForSearch(name) || name;
        const scriptCandidates = await scriptBloxSearch(scriptSearchName);
        const matchedScripts = filterScriptsForGame(scriptCandidates, {
            gameName: name,
            rootPlaceId,
        });
        const gameScripts: ScriptBloxScript[] = await Promise.all(
            matchedScripts.slice(0, 4).map(async (script) => ({
                ...script,
                featureLines: await fetchScriptBloxFeatures(script.id),
            })),
        );

        // Multi-site web research via Bing, with DuckDuckGo and Mojeek as
        // fallbacks when Bing blocks or challenges the host. Emoji and other
        // non-ASCII in game names confuse search engines, so queries use a
        // sanitized copy.
        const searchName = sanitizeForSearch(name) || name;
        const rawSearches: SearchResult[] = [];
        const seenUrls = new Set<string>();
        for (const query of [
            `${searchName} roblox wiki features`,
            `${searchName} roblox how to play guide`,
            `${searchName} roblox game mechanics list`,
        ]) {
            if (rawSearches.length >= MAX_BING_RESULTS)
                break;
            for (const result of await webSearch(query)) {
                if (seenUrls.has(result.url))
                    continue;
                seenUrls.add(result.url);
                rawSearches.push(result);
            }
        }
        // Search engines relax obscure queries into generic matches (a
        // "Volleyball Legends" search degrades into pages about the sport),
        // so keep only results that actually mention this game.
        const searches = filterRelevantResults(rawSearches, name);
        if (searches.length === 0 && gameScripts.length === 0)
            return toolTextResponse(
                `Web research found nothing relevant for "${name}" — every search provider (Bing, DuckDuckGo, Mojeek) was unreachable, blocked, or only returned generic content unrelated to this game, and no community scripts were found on ScriptBlox. The game may be too new or too small to have public documentation.`,
                {},
                true,
            );

        // Fandom wiki deep-dive if any result points at one.
        const fandomHost = searches.find((r) => r.host.endsWith("fandom.com"))?.host;
        let wikiPages: WikiPage[] = [];
        if (fandomHost) {
            const found = await fandomWikiSearch(fandomHost, `${name} features guide`);
            const guideTitles = found.map((entry) => entry.title);
            const extra = guideTitles.length < MAX_WIKI_PAGES
                ? await fandomWikiSearch(fandomHost, `${name} gameplay`)
                : [];
            const titles = [...guideTitles, ...extra.map((entry) => entry.title)]
                .filter((value, index, array) => array.indexOf(value) === index)
                .slice(0, MAX_WIKI_PAGES);
            wikiPages = await fandomFetchExtracts(fandomHost, titles);
        }

        const featureMap = compileFeatureMap({
            gameName: name,
            placeId: resolvedPlaceId,
            universeId,
            searchResults: searches,
            wikiHost: fandomHost,
            wikiPages,
            scripts: gameScripts,
        });
        return toolTextResponse(featureMap, {
            maxOutputChars,
            truncationHint: "Rerun research-game with a gameName plus narrower focus, or lower maxOutputChars is not the issue — the map is large.",
        });
    });
}
