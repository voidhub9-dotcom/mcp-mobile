import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
    getActiveClients,
    getClientById,
    HTTP_CLIENT_ACTIVE_GRACE_MS,
    registerClient,
    resetRegistry,
} from "../dist/bridge/handlers/shared/registry.js";
import { HTTP_CLIENT_GRACE_MS, TOOL_RESPONSE_TIMEOUT } from "../dist/config.js";

const connectorSources = [
    new URL("../connector-src/mobile-connector.luau", import.meta.url),
    new URL("../mobile-connector.luau", import.meta.url),
];

// The root copy is what /mobile-connector.luau actually serves to executors, so a
// fix that only lands in connector-src/ never reaches a real device.
const [connectorSrc, servedConnector] = connectorSources.map((url) => readFileSync(url, "utf8"));
assert.equal(
    connectorSrc,
    servedConnector,
    "mobile-connector.luau in the project root must stay in sync with connector-src/",
);

// A re-registration is a healthy session ending on purpose. If Connect() can only
// ever report failure, the reconnect loop doubles its delay every single time and
// walks straight past the window in which the server still considers the client
// connected — which is exactly what makes the dashboard flap.
assert.match(
    connectorSrc,
    /needsReregister\s*=\s*true/,
    "a 404 re-registration must be recorded as a deliberate, healthy session end",
);
assert.match(
    connectorSrc,
    /if needsReregister then\s*\n\s*return true/,
    "Connect must be able to report a healthy session so the backoff resets",
);

const maxReconnect = connectorSrc.match(/local MAX_RECONNECT_DELAY = (\d+)/);
assert.ok(maxReconnect, "the reconnect ceiling must be a named constant");
const maxReconnectMs = Number(maxReconnect[1]) * 1000;

// Worst case before the server may next hear from a struggling-but-alive client:
// poll backoff, then the reconnect sleep, then the liveness probe and re-register.
const WORST_CASE_SILENCE_MS = 8_000 + maxReconnectMs + 5_000 + 5_000;
assert.ok(
    HTTP_CLIENT_ACTIVE_GRACE_MS > WORST_CASE_SILENCE_MS,
    `the active-client grace (${HTTP_CLIENT_ACTIVE_GRACE_MS}ms) must outlast the connector's ` +
        `worst-case reconnect (${WORST_CASE_SILENCE_MS}ms), or a client that is coming back ` +
        "is declared dead before it can return",
);

assert.equal(HTTP_CLIENT_ACTIVE_GRACE_MS, HTTP_CLIENT_GRACE_MS, "grace window should be configurable");
assert.ok(TOOL_RESPONSE_TIMEOUT >= 30_000, "mobile round trips need more than a few seconds");

// A client silent for an ordinary backgrounded-app gap stays connected.
resetRegistry();
const clientId = registerClient({
    username: "StabilityPlayer",
    userId: 11,
    placeId: 555,
    jobId: "stability-job",
    placeName: "Stability Place",
    sessionId: "stability-session",
    transport: "http",
});
const client = getClientById(clientId);
assert.ok(client, "test client should be registered");

client.lastHttpPoll = Date.now() - WORST_CASE_SILENCE_MS;
assert.ok(
    getActiveClients().some((entry) => entry.clientId === clientId),
    "a client inside its worst-case reconnect window must still count as connected",
);

client.lastHttpPoll = Date.now() - HTTP_CLIENT_ACTIVE_GRACE_MS - 1;
assert.ok(
    !getActiveClients().some((entry) => entry.clientId === clientId),
    "a client past the whole grace window must still eventually go inactive",
);

resetRegistry();
console.log("connection stability test passed");
