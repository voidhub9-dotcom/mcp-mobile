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
    return name.replace(/[^\x20-\x7E]/g, " ").replace(/\s+/g, " ").trim();
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
}): string {
    const { gameName, placeId, universeId, searchResults, wikiHost, wikiPages } = input;
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
        if (resolvedPlaceId !== undefined) {
            universeId = await resolveUniverseId(resolvedPlaceId);
            if (!name)
                name = await fetchGameNameFromPlace(resolvedPlaceId) ?? undefined;
        }
        if (!name)
            return toolTextResponse(
                "Could not resolve the game name. Provide gameName explicitly.",
                {},
                true,
            );

        // Multi-site web research via Bing. Emoji and other non-ASCII in game
        // names confuse search engines, so queries use a sanitized copy.
        const searchName = sanitizeForSearch(name) || name;
        const searches: SearchResult[] = [];
        const seenUrls = new Set<string>();
        for (const query of [
            `${searchName} roblox wiki features`,
            `${searchName} roblox how to play guide`,
            `${searchName} roblox game mechanics list`,
        ]) {
            if (searches.length >= MAX_BING_RESULTS)
                break;
            for (const result of await bingSearch(query)) {
                if (seenUrls.has(result.url))
                    continue;
                seenUrls.add(result.url);
                searches.push(result);
            }
        }
        if (searches.length === 0)
            return toolTextResponse(
                `Web research found nothing for "${name}" — every source was unreachable or empty. The game may be too new or too small to have public documentation.`,
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
        });
        return toolTextResponse(featureMap, {
            maxOutputChars,
            truncationHint: "Rerun research-game with a gameName plus narrower focus, or lower maxOutputChars is not the issue — the map is large.",
        });
    });
}
