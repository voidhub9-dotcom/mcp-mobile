import { DISCORD_API_BASE, DISCORD_CLIENT_ID, DISCORD_HTTP_TIMEOUT_MS } from "./config.js";

// Resolves a Rich Presence art-asset key (e.g. "void_logo") to its CDN image,
// so the /auth/discord page can preview the presence exactly as Discord shows it.

const TTL_MS = 10 * 60_000;
let cached: { at: number; assets: { id: string; name: string }[] } | null = null;

async function loadAssets(): Promise<{ id: string; name: string }[]> {
    if (cached && Date.now() - cached.at < TTL_MS)
        return cached.assets;
    let assets: { id: string; name: string }[] = [];
    try {
        const resp = await fetch(`${DISCORD_API_BASE}/oauth2/applications/${DISCORD_CLIENT_ID}/assets`, {
            signal: AbortSignal.timeout(DISCORD_HTTP_TIMEOUT_MS),
        });
        if (resp.ok) {
            const body = (await resp.json()) as unknown;
            if (Array.isArray(body))
                assets = body.filter((a): a is { id: string; name: string } => typeof a?.id === "string" && typeof a?.name === "string");
        }
    }
    catch {
        // preview only: ignore
    }
    cached = { at: Date.now(), assets };
    return assets;
}

/** https URL for an asset key or URL, or null if it can't be resolved. */
export async function resolveAssetImage(keyOrUrl: string): Promise<string | null> {
    if (/^https:\/\//i.test(keyOrUrl))
        return keyOrUrl;
    if (!DISCORD_CLIENT_ID)
        return null;
    const asset = (await loadAssets()).find((a) => a.name === keyOrUrl);
    return asset ? `https://cdn.discordapp.com/app-assets/${DISCORD_CLIENT_ID}/${asset.id}.png?size=256` : null;
}

/** Resolve within `ms`, else null: page renders never wait long on third parties. */
export function within<T>(promise: Promise<T | null>, ms: number): Promise<T | null> {
    return Promise.race([promise.catch(() => null), new Promise<null>((r) => setTimeout(() => r(null), ms).unref?.())]);
}
