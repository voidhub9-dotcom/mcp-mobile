import { DISCORD_HTTP_TIMEOUT_MS } from "./config.js";

// Looks up a Roblox game's icon so Rich Presence can show the game you're in.
// Uses Roblox's public thumbnails API (no auth). Results are cached; failures
// return null so the caller falls back to the Void Hub logo.

const ICON_TTL_MS = 60 * 60_000;
const MISS_TTL_MS = 5 * 60_000;
const cache = new Map<number, { url: string | null; at: number }>();
const inflight = new Map<number, Promise<string | null>>();

export function gameIconApiUrl(placeId: number): string {
    return `https://thumbnails.roblox.com/v1/places/gameicons?placeIds=${placeId}&returnPolicy=PlaceHolder&size=512x512&format=Png&isCircular=false`;
}

export async function getGameIconUrl(placeId: number): Promise<string | null> {
    if (!Number.isFinite(placeId) || placeId <= 0)
        return null;
    const hit = cache.get(placeId);
    if (hit && Date.now() - hit.at < (hit.url ? ICON_TTL_MS : MISS_TTL_MS))
        return hit.url;
    const pending = inflight.get(placeId);
    if (pending)
        return pending;
    const run = (async () => {
        let url: string | null = null;
        try {
            const resp = await fetch(gameIconApiUrl(placeId), { signal: AbortSignal.timeout(DISCORD_HTTP_TIMEOUT_MS) });
            if (resp.ok) {
                const body = (await resp.json()) as { data?: { state?: string; imageUrl?: string }[] };
                const entry = body.data?.[0];
                if (entry?.state === "Completed" && typeof entry.imageUrl === "string" && entry.imageUrl.startsWith("https://"))
                    url = entry.imageUrl;
            }
        }
        catch {
            // network error / timeout: fall back to the logo
        }
        cache.set(placeId, { url, at: Date.now() });
        return url;
    })();
    inflight.set(placeId, run);
    try {
        return await run;
    }
    finally {
        inflight.delete(placeId);
    }
}
