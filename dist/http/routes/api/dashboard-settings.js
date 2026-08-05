import { dashboardSettingsExist, loadDashboardSettings, saveDashboardSettings, } from "../../../dashboard/settings.js";
import { readJsonBody } from "../../body.js";
function respondJson(res, status, body) {
    res.writeHead(status, {
        "Content-Type": "application/json",
        "Cache-Control": "no-store",
    });
    res.end(JSON.stringify(body));
}
export async function GET(_req, res) {
    const [settings, persisted] = await Promise.all([
        loadDashboardSettings(),
        dashboardSettingsExist(),
    ]);
    respondJson(res, 200, { ...settings, persisted });
}
export async function PUT(req, res) {
    try {
        const body = await readJsonBody(req);
        const settings = await saveDashboardSettings(body);
        respondJson(res, 200, { ...settings, persisted: true });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : "Invalid dashboard settings.";
        respondJson(res, 400, { error: message });
    }
}
