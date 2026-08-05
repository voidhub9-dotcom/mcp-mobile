import { getClientById } from "../../bridge/handlers/shared/registry.js";
import { getCachedScriptSourcesByScriptHash, } from "../../bridge/handlers/shared/script-source-store.js";
import { readJsonBody } from "../body.js";
function json(res, status, body) {
    res.writeHead(status, { "Content-Type": "application/json" });
    res.end(JSON.stringify(body));
}
export async function POST(req, res) {
    try {
        const body = await readJsonBody(req);
        const client = body.clientId ? getClientById(body.clientId) : undefined;
        if (!body.clientId || !client) {
            json(res, 404, { error: "Unknown clientId" });
            return;
        }
        const hashes = Array.isArray(body.hashes) ? body.hashes : [];
        const identity = {
            clientId: client.clientId,
            placeId: client.placeId,
            jobId: client.jobId,
        };
        const sources = getCachedScriptSourcesByScriptHash(identity, hashes);
        json(res, 200, {
            ok: true,
            sources: sources.map((source) => ({
                scriptHash: source.scriptHash,
                source: source.source,
                sourceHash: source.sourceHash,
                debugId: source.debugId,
                path: source.path,
                updatedAt: source.updatedAt,
            })),
        });
    }
    catch {
        json(res, 400, { error: "Invalid JSON" });
    }
}
