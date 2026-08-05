import { loadDecompilerSettings, saveDecompilerSettings, toPublicDecompilerSettings, } from "../../../decompiler/settings.js";
import { getDecompilerHealthSnapshot } from "../../../decompiler/health.js";
import { readJsonBody } from "../../body.js";
import { getActiveClientId } from "../../../bridge/handlers/shared/registry.js";
function selectedClientId(req) {
    const url = new URL(req.url ?? "/api/decompiler-settings", "http://localhost");
    return url.searchParams.get("clientId")?.slice(0, 160) || getActiveClientId();
}
export async function GET(req, res) {
    const settings = await loadDecompilerSettings();
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify(toPublicDecompilerSettings(settings, getDecompilerHealthSnapshot(selectedClientId(req)))));
}
export async function PUT(req, res) {
    try {
        const body = await readJsonBody(req);
        const settings = await saveDecompilerSettings(body);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify(toPublicDecompilerSettings(settings, getDecompilerHealthSnapshot(selectedClientId(req)))));
    }
    catch (error) {
        const message = error instanceof Error ? error.message : "Invalid decompiler settings.";
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: message }));
    }
}
