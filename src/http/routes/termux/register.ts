import type { IncomingMessage, ServerResponse } from "http";
import crypto from "crypto";
import { registerClient } from "../../../bridge/handlers/shared/registry.js";
import { readJsonBody } from "../../body.js";

interface TermuxRegisterBody {
    token?: string;
    name?: string;
}

export const TERMUX_EXECUTOR = "termux-agent";
export const TERMUX_PLATFORM = "android";
export const PHONE_SHELL_CAPABILITY = "phone-shell";

function tokenMatches(provided: string, expected: string): boolean {
    const a = Buffer.from(provided, "utf8");
    const b = Buffer.from(expected, "utf8");
    if (a.length !== b.length)
        return false;
    return crypto.timingSafeEqual(a, b);
}

/**
 * Registers a Termux agent as an HTTP bridge client. Agents authenticate with
 * the TERMUX_TOKEN environment variable configured on the server; once
 * registered they receive `phone-shell` messages through the normal
 * /poll long-poll and answer through /respond, exactly like the in-game
 * connectors.
 */
export async function POST(req: IncomingMessage, res: ServerResponse): Promise<void> {
    const expected = process.env.TERMUX_TOKEN;
    if (!expected) {
        res.writeHead(503, { "Content-Type": "application/json" });
        res.end(JSON.stringify({
            error: "TERMUX_TOKEN is not configured on this server. Set the TERMUX_TOKEN environment variable and redeploy, then retry.",
        }));
        return;
    }
    try {
        const info = await readJsonBody<TermuxRegisterBody>(req);
        if (!info.token || !tokenMatches(String(info.token), expected)) {
            res.writeHead(401, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ error: "Invalid termux agent token." }));
            return;
        }
        const name = (info.name || "termux").trim().slice(0, 40) || "termux";
        const clientId = registerClient({
            username: name,
            userId: 0,
            placeId: 0,
            jobId: "",
            placeName: "Termux Shell",
            // Stable session id: agent restarts refresh the same client entry.
            sessionId: "termux-agent",
            transport: "http",
            mobile: true,
            executor: TERMUX_EXECUTOR,
            platform: TERMUX_PLATFORM,
            capabilities: { [PHONE_SHELL_CAPABILITY]: true },
        });
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ clientId }));
    }
    catch {
        res.writeHead(400);
        res.end("Invalid JSON");
    }
}
