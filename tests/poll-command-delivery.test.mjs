import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { SendToClient } from "../dist/bridge/handlers/shared/communication.js";
import {
    getClientById,
    registerClient,
    resetRegistry,
} from "../dist/bridge/handlers/shared/registry.js";
import { GET as pollGET } from "../dist/http/routes/poll.js";

function makeReq() {
    const req = new EventEmitter();
    req.method = "GET";
    return req;
}

// Stands in for a ServerResponse whose underlying socket has gone away. Node
// delivers the request 'close' event asynchronously, so there is a real window
// where the response object is already unwritable while the poll handler still
// believes it can answer.
function makeDeadRes() {
    return {
        destroyed: true,
        writableEnded: false,
        writable: false,
        written: [],
        writeHead() {
            throw new Error("wrote a header to a destroyed response");
        },
        end() {
            throw new Error("wrote a body to a destroyed response");
        },
    };
}

function makeLiveRes() {
    const res = {
        destroyed: false,
        writableEnded: false,
        writable: true,
        statusCode: 0,
        body: undefined,
        writeHead(status) {
            res.statusCode = status;
        },
        end(body) {
            res.writableEnded = true;
            res.body = body;
        },
    };
    return res;
}

function newClient(sessionId) {
    const clientId = registerClient({
        username: "DeliveryPlayer",
        userId: 7,
        placeId: 321,
        jobId: "delivery-job",
        placeName: "Delivery Place",
        sessionId,
        transport: "http",
    });
    const client = getClientById(clientId);
    assert.ok(client, "test client should be registered");
    return client;
}

const pollUrl = (clientId) => new URL(`http://localhost/poll?clientId=${clientId}`);

// 1. A command dispatched while the long-poll socket is already dead must not be
//    lost: it has to stay queued so the next poll delivers it.
{
    resetRegistry();
    const client = newClient("delivery-session-dead");
    pollGET(makeReq(), makeDeadRes(), pollUrl(client.clientId));
    assert.ok(client.pendingPollResolve, "poll should be parked waiting for commands");

    SendToClient(client, '{"id":"cmd-1"}');

    assert.deepEqual(
        client.pendingHttpCommands,
        ['{"id":"cmd-1"}'],
        "a command that could not be written must be requeued, not dropped",
    );

    // The next poll on a healthy socket delivers it.
    const res = makeLiveRes();
    pollGET(makeReq(), res, pollUrl(client.clientId));
    assert.equal(res.statusCode, 200, "queued commands must be flushed to the next poll");
    assert.equal(res.body, '[{"id":"cmd-1"}]');
    assert.deepEqual(client.pendingHttpCommands, [], "queue must drain once delivered");
}

// 2. A command that arrives after the request 'close' event must also survive.
{
    resetRegistry();
    const client = newClient("delivery-session-closed");
    const req = makeReq();
    pollGET(req, makeLiveRes(), pollUrl(client.clientId));
    req.emit("close");
    assert.equal(client.pendingPollResolve, null, "closing a poll must clear its waiter");

    SendToClient(client, '{"id":"cmd-2"}');
    assert.deepEqual(
        client.pendingHttpCommands,
        ['{"id":"cmd-2"}'],
        "a command dispatched after close must stay queued",
    );
}

// 3. Ordering is preserved when a requeued command meets a newly dispatched one.
{
    resetRegistry();
    const client = newClient("delivery-session-order");
    pollGET(makeReq(), makeDeadRes(), pollUrl(client.clientId));
    SendToClient(client, '{"id":"first"}');
    SendToClient(client, '{"id":"second"}');

    assert.deepEqual(
        client.pendingHttpCommands,
        ['{"id":"first"}', '{"id":"second"}'],
        "requeued commands must keep dispatch order",
    );
}

// 4. The happy path still answers the parked poll directly.
{
    resetRegistry();
    const client = newClient("delivery-session-live");
    const res = makeLiveRes();
    pollGET(makeReq(), res, pollUrl(client.clientId));
    SendToClient(client, '{"id":"cmd-3"}');

    assert.equal(res.statusCode, 200, "a live parked poll must receive the command");
    assert.equal(res.body, '[{"id":"cmd-3"}]');
    assert.deepEqual(client.pendingHttpCommands, [], "delivered commands must not stay queued");
}

resetRegistry();
console.log("poll command delivery test passed");
