import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { IncomingMessage, ServerResponse } from "http";
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const AGENT_PATH = path.resolve(__dirname, "../../../../termux/agent.sh");
export async function GET(_req: IncomingMessage, res: ServerResponse): Promise<void> {
    try {
        const source = await fs.readFile(AGENT_PATH, "utf8");
        res.writeHead(200, {
            "Content-Type": "text/x-shellscript; charset=utf-8",
            "Cache-Control": "no-store",
        });
        res.end(source);
    }
    catch (error) {
        console.error("[termux/agent.sh] Failed to read agent script:", error);
        res.writeHead(500, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("Failed to load termux/agent.sh. Make sure the file exists in the repo.");
    }
}
