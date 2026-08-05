import { loadDecompilerSettings, toConnectorDecompilerSettings, } from "../../../../decompiler/settings.js";
import { ensureConfiguredLocalDecompilerProvidersRunning, isLocalDecompilerSetupRequest, } from "./setup.js";
export async function GET(req, res) {
    const settings = await loadDecompilerSettings();
    if (isLocalDecompilerSetupRequest(req)) {
        await ensureConfiguredLocalDecompilerProvidersRunning(settings);
    }
    res.writeHead(200, {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
    });
    res.end(JSON.stringify(toConnectorDecompilerSettings(settings)));
}
