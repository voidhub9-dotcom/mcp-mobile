import { requeueCommands } from "../../bridge/handlers/shared/communication.js";
import { getClientById } from "../../bridge/handlers/shared/registry.js";
import { HTTP_POLL_TIMEOUT } from "../../config.js";
function canWrite(res) {
    return !res.destroyed && !res.writableEnded && res.writable !== false;
}
function sendCommands(res, commands) {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end("[" + commands.join(",") + "]");
}
export function GET(req, res, url) {
    const clientId = url.searchParams.get("clientId");
    if (!clientId) {
        res.writeHead(400);
        res.end("Missing clientId query parameter");
        return;
    }
    const client = getClientById(clientId);
    if (!client) {
        res.writeHead(404);
        res.end("Unknown clientId");
        return;
    }
    client.lastHttpPoll = Date.now();
    if (client.pendingHttpCommands.length > 0) {
        const commands = client.pendingHttpCommands;
        client.pendingHttpCommands = [];
        if (!canWrite(res)) {
            requeueCommands(client, commands);
            return;
        }
        sendCommands(res, commands);
        return;
    }
    client.pendingPollResolve?.([]);
    let done = false;
    const finish = (commands) => {
        // The dispatcher hands its batch over before knowing whether this response
        // is still usable, so every path that cannot deliver must put it back.
        if (done) {
            requeueCommands(client, commands);
            return;
        }
        done = true;
        clearTimeout(timer);
        if (client.pendingPollResolve === finish)
            client.pendingPollResolve = null;
        if (!canWrite(res)) {
            requeueCommands(client, commands);
            return;
        }
        if (commands.length === 0) {
            res.writeHead(204);
            res.end();
            return;
        }
        sendCommands(res, commands);
    };
    const timer = setTimeout(() => finish([]), HTTP_POLL_TIMEOUT);
    client.pendingPollResolve = finish;
    req.on("close", () => {
        if (done)
            return;
        done = true;
        clearTimeout(timer);
        if (client.pendingPollResolve === finish)
            client.pendingPollResolve = null;
    });
}
