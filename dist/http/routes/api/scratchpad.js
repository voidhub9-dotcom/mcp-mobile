import { readJsonBody } from "../../body.js";
import { scratchpadWrite, scratchpadRead, scratchpadList, scratchpadDelete, scratchpadClear, } from "../../../scratchpad/store.js";
export async function GET(req, res, url) {
    const key = url.searchParams.get("key");
    if (key) {
        const entry = scratchpadRead(key);
        if (!entry) {
            res.writeHead(404, { "Content-Type": "application/json" });
            res.end(JSON.stringify({ error: `Key not found: ${key}` }));
            return;
        }
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify(entry));
        return;
    }
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ entries: scratchpadList() }));
}
export async function POST(req, res) {
    let parsed;
    try {
        parsed = await readJsonBody(req);
    }
    catch {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Invalid JSON body." }));
        return;
    }
    const { key, value, source } = parsed;
    if (typeof key !== "string" || typeof value !== "string") {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: "Fields 'key' and 'value' are required strings." }));
        return;
    }
    const result = scratchpadWrite(key, value, typeof source === "string" ? source : "mobile");
    if (!result.ok) {
        res.writeHead(400, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ error: result.error }));
        return;
    }
    const entry = scratchpadRead(key);
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true, entry }));
}
export async function DELETE(_req, res, url) {
    const key = url.searchParams.get("key");
    if (key) {
        const deleted = scratchpadDelete(key);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true, deleted }));
        return;
    }
    const cleared = scratchpadClear();
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ ok: true, cleared }));
}
