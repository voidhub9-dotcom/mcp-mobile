import assert from "node:assert/strict";
import { mkdtempSync, readFileSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { test, mock } from "node:test";

// Configure the Discord feature before the modules read process.env.
const tmp = mkdtempSync(path.join(os.tmpdir(), "voidhub-rpc-"));
process.env.DISCORD_CLIENT_ID = "123";
process.env.DISCORD_CLIENT_SECRET = "secret";
process.env.DISCORD_REDIRECT_URI = "https://example.test/auth/discord/callback";
process.env.DISCORD_BUTTON_URL = "https://example.test/get";
process.env.TOKEN_ENCRYPTION_KEY = "11".repeat(32);
process.env.DISCORD_TOKEN_STORE_PATH = path.join(tmp, "links.json");

const store = await import("../dist/discord/token-store.js");
const oauth = await import("../dist/discord/oauth.js");
const presence = await import("../dist/discord/discordPresence.js");
const hook = await import("../dist/discord/tool-hook.js");

const calls = [];
function installFetch(handler) {
    globalThis.fetch = async (url, init = {}) => {
        const body = init.body ? (typeof init.body === "string" && init.body.startsWith("{") ? JSON.parse(init.body) : String(init.body)) : null;
        calls.push({ url: String(url), body, auth: init.headers?.Authorization });
        return handler(String(url), body);
    };
}
const json = (status, value) => new Response(JSON.stringify(value), { status, headers: { "Content-Type": "application/json" } });
// setImmediate is not mocked, so this lets real fs/promise work finish between fake timer ticks.
const flush = async () => { for (let i = 0; i < 300; i++) await new Promise((r) => setImmediate(r)); };
// Poll (on real setImmediate turns, up to ~5s of wall time) until a condition holds.
// Fake time advances by `advanceMs` per poll, but never more than `maxAdvanceMs` in total,
// so slow real I/O can't let fake time race past the idle timeout.
async function waitFor(cond, label, advanceMs = 0, maxAdvanceMs = 60_000) {
    const deadline = performance.now() + 5000;
    let advanced = 0;
    while (!cond()) {
        if (performance.now() > deadline) assert.fail(`timed out waiting for: ${label}`);
        if (advanceMs && advanced < maxAdvanceMs) { mock.timers.tick(advanceMs); advanced += advanceMs; }
        await new Promise((r) => setImmediate(r));
    }
}
const pushes = () => calls.filter((c) => c.url.endsWith("/headless-sessions"));

test("authorize URL requests the Social SDK scopes with a one-time state", () => {
    const { url, state } = oauth.createAuthorizeUrl("default");
    const u = new URL(url);
    assert.equal(u.searchParams.get("scope"), "openid sdk.social_layer_presence");
    assert.equal(u.searchParams.get("state"), state);
    assert.equal(oauth.consumeState(state), "default");
    assert.equal(oauth.consumeState(state), null, "state is single-use");
});

test("tokens are encrypted at rest and decrypt back", async () => {
    installFetch(() => json(200, {
        access_token: "AT1", refresh_token: "RT1", expires_in: 604800, scope: "openid sdk.social_layer_presence", token_type: "Bearer",
        id_token: `x.${Buffer.from(JSON.stringify({ sub: "999" })).toString("base64url")}.y`,
    }));
    const link = await oauth.exchangeCode("default", "CODE");
    assert.equal(link.discordUserId, "999");
    const raw = readFileSync(process.env.DISCORD_TOKEN_STORE_PATH, "utf8");
    assert.ok(!raw.includes("AT1") && !raw.includes("RT1"), "plaintext tokens must not hit disk");
    assert.equal(calls.at(-1).body.includes("grant_type=authorization_code"), true);
});

test("expired tokens are refreshed before use", async () => {
    const link = await store.getLink("default");
    await store.saveLink("default", { ...link, expiresAt: Date.now() + 1000 });
    installFetch(() => json(200, { access_token: "AT2", refresh_token: "RT2", expires_in: 604800, scope: "x", token_type: "Bearer" }));
    const fresh = await oauth.getValidLink("default");
    assert.equal(fresh.accessToken, "AT2");
    assert.ok(calls.at(-1).body.includes("grant_type=refresh_token"));
});

test("tool hook never blocks or fails the tool, and presence is throttled + cleared on idle", async () => {
    mock.timers.enable({ apis: ["setTimeout", "setInterval", "Date"], now: Date.now() });
    try {
        calls.length = 0;
        let hang = true;
        let release;
        installFetch((url) => {
            if (url.endsWith("/headless-sessions/delete"))
                return json(204, {});
            if (url.endsWith("/headless-sessions")) {
                // First call hangs to prove the tool doesn't wait on Discord.
                if (hang) {
                    hang = false;
                    return new Promise((r) => { release = () => r(json(200, { token: "SESSION0", activities: [] })); });
                }
                return json(200, { token: "SESSION1", activities: [] });
            }
            return json(500, {});
        });

        const registered = {};
        const fakeServer = { registerTool(name, _cfg, cb) { registered[name] = cb; } };
        hook.installPresenceToolHook(fakeServer);
        fakeServer.registerTool("execute", {}, async () => "tool-ran");

        assert.equal(await registered.execute({}), "tool-ran", "tool result passes through untouched");
        mock.timers.tick(0);
        await waitFor(() => pushes().length === 1, "first push");
        const first = pushes();
        assert.equal(first.length, 1);
        const act = first[0].body.activities[0];
        assert.equal(act.name, "VoidHub RPC");
        assert.equal(act.type, 0);
        assert.equal(act.platform, "desktop", "Discord requires activities[].platform");
        assert.equal(act.details, "🛠️ Building a script", "execute = building stage");
        assert.equal(act.state, "Connected via VoidHub MCP");
        assert.equal(act.assets.large_image, "https://pastevoid.lovable.app/img/Ru7BnfAV0N.png", "no void_logo Art Asset uploaded, so the logo URL is used");
        assert.equal(act.assets.large_text, "VoidHub MCP");
        assert.deepEqual(act.buttons, [{ label: "Get VoidHub", url: "https://example.test/get" }]);
        assert.equal(first[0].auth, "Bearer AT2");
        // The tool already returned while Discord was still "hanging"; now let it finish.
        release();
        // Wait until that push has fully finished (its session token is persisted).
        for (let i = 0; i < 5000 && (await store.getLink("default"))?.sessionToken !== "SESSION0"; i++)
            await new Promise((r) => setImmediate(r));
        assert.equal((await store.getLink("default")).sessionToken, "SESSION0");
        await flush();

        presence.updateUserPresence("default", "Running remote-spy");
        mock.timers.tick(1000);
        await flush();
        assert.equal(pushes().length, 1, "throttled: no second push inside the 15s window");
        // Let the earlier push fully settle (real I/O), then jump past the throttle window.
        await waitFor(() => !presence.getPresenceStatus("default").pushInFlight, "first push settled");
        assert.equal(presence.getPresenceStatus("default").pushScheduled, true, "update is queued, not sent");
        mock.timers.tick(16_000);
        await waitFor(() => pushes().length === 2, "second push after throttle window");
        await waitFor(() => !presence.getPresenceStatus("default").pushInFlight, "second push settled");
        assert.equal(pushes()[1].body.activities[0].details, "Running remote-spy");

        // Idle: after 5 min with no tool calls, the session is ended.
        for (let i = 0; i < 12 && presence.getPresenceStatus("default").active; i++) {
            mock.timers.tick(30_000);
            await flush();
        }
        await waitFor(() => calls.some((c) => c.url.endsWith("/headless-sessions/delete")), "headless session delete", 30_000, 10 * 60_000);
        assert.equal(presence.getPresenceStatus("default").active, false);
        const del = calls.filter((c) => c.url.endsWith("/headless-sessions/delete"));
        assert.equal(del.length, 1, "idle timeout ends the headless session");
        assert.equal(del[0].body.token, "SESSION1");
    }
    finally {
        mock.timers.reset();
    }
});

test("game icon becomes the big image, with the VoidHub logo as the small badge", () => {
    const act = presence.buildActivity("Making a script", 1, {
        game: { placeId: 606849621, placeName: "Cool Game" },
        gameIconUrl: "https://tr.rbxcdn.com/icon.png",
    });
    assert.deepEqual(act.assets, {
        large_image: "https://tr.rbxcdn.com/icon.png",
        large_text: "Cool Game",
        small_image: "void_logo",
        small_text: "VoidHub MCP",
    });
    assert.equal(act.name, "Cool Game", "title is the game's name, like other executor RPCs");
    assert.deepEqual(act.buttons, [
        { label: "See Game Page", url: "https://www.roblox.com/games/606849621" },
        { label: "Get VoidHub", url: "https://example.test/get" },
    ]);
    const plain = presence.buildActivity("Making a script", 1);
    assert.equal(plain.name, "VoidHub RPC");
    assert.deepEqual(plain.assets, { large_image: "void_logo", large_text: "VoidHub MCP" });
});

test("presence fetches the Roblox game icon and falls back to the logo if Discord rejects it", async () => {
    await presence.clearUserPresence("default"); // start from a clean session
    calls.length = 0;
    let rejectedOnce = false;
    installFetch((url, body) => {
        if (url.startsWith("https://thumbnails.roblox.com/"))
            return json(200, { data: [{ targetId: 606849621, state: "Completed", imageUrl: "https://tr.rbxcdn.com/icon.png" }] });
        if (url.endsWith("/headless-sessions")) {
            if (body.activities[0].assets.large_image.startsWith("https://") && !rejectedOnce) {
                rejectedOnce = true;
                return json(400, { message: "Invalid asset image url" });
            }
            return json(200, { token: "SESSION2", activities: [] });
        }
        return json(204, {});
    });
    presence.updateUserPresence("default", "Making a script", { placeId: 606849621, placeName: "Cool Game" });
    const deadline = Date.now() + 5000;
    while (calls.filter((c) => c.url.endsWith("/headless-sessions")).length < 2 && Date.now() < deadline)
        await new Promise((r) => setTimeout(r, 5));
    const sent = calls.filter((c) => c.url.endsWith("/headless-sessions"));
    assert.ok(calls.some((c) => c.url.includes("placeIds=606849621")), "looks up the icon for the current place");
    assert.equal(sent[0].body.activities[0].assets.large_image, "https://tr.rbxcdn.com/icon.png");
    assert.equal(sent[0].body.activities[0].assets.large_text, "Cool Game");
    assert.equal(sent[1].body.activities[0].assets.large_image, "https://pastevoid.lovable.app/img/Ru7BnfAV0N.png", "falls back to the logo");
    assert.equal(presence.getPresenceStatus("default").game.placeName, "Cool Game");
    await presence.clearUserPresence("default");
});

test("test presence pushes immediately and reports Discord's error", async () => {
    installFetch((url) => url.endsWith("/headless-sessions")
        ? json(403, { message: "Missing Access", code: 50001 })
        : json(204, {}));
    const bad = await presence.sendTestPresence("default", "Testing VoidHub RPC", null);
    assert.equal(bad.ok, false);
    assert.match(bad.error, /403.*Missing Access/);
    installFetch((url) => url.endsWith("/headless-sessions") ? json(200, { token: "S3", activities: [] }) : json(204, {}));
    const good = await presence.sendTestPresence("default", "Testing VoidHub RPC", null);
    assert.deepEqual(good, { ok: true });
    await presence.clearUserPresence("default");
});

test("joining a game starts the presence with no tool call; leaving clears it", async () => {
    await presence.clearUserPresence("default");
    calls.length = 0;
    installFetch((url) => {
        if (url.startsWith("https://thumbnails.roblox.com/"))
            return json(200, { data: [{ state: "Completed", imageUrl: "https://tr.rbxcdn.com/game.png" }] });
        if (url.endsWith("/headless-sessions"))
            return json(200, { token: "G1", activities: [] });
        return json(204, {});
    });
    const registry = await import("../dist/bridge/handlers/shared/registry.js");
    const clientId = registry.registerClient({ username: "p", userId: 1, placeId: 12345, jobId: "j", placeName: "Crash Engine", transport: "http", mobile: true });
    const entry = registry.getClientById(clientId);
    entry.lastHttpPoll = Date.now();
    hook.checkGamePresence();
    const deadline = Date.now() + 5000;
    while (!calls.some((c) => c.url.endsWith("/headless-sessions")) && Date.now() < deadline)
        await new Promise((r) => setTimeout(r, 5));
    const act = calls.find((c) => c.url.endsWith("/headless-sessions")).body.activities[0];
    assert.equal(act.name, "Crash Engine");
    assert.equal(act.details, "Using VoidHub");
    // (the game icon itself is covered by the icon test; an earlier test switches icons off for this run)
    assert.deepEqual(act.buttons[0], { label: "See Game Page", url: "https://www.roblox.com/games/12345" });
    assert.equal(presence.getPresenceStatus("default").active, true);

    registry.unregisterClient(clientId);
    hook.checkGamePresence();
    assert.equal(presence.getPresenceStatus("default").active, true, "one missed check is tolerated (teleport/server hop)");
    hook.checkGamePresence();
    const deadline2 = Date.now() + 5000;
    while (presence.getPresenceStatus("default").active && Date.now() < deadline2)
        await new Promise((r) => setTimeout(r, 5));
    assert.equal(presence.getPresenceStatus("default").active, false, "leaving the game clears the presence");
    const deadline3 = Date.now() + 5000;
    while (!calls.some((c) => c.url.endsWith("/headless-sessions/delete")) && Date.now() < deadline3)
        await new Promise((r) => setTimeout(r, 5));
    assert.ok(calls.some((c) => c.url.endsWith("/headless-sessions/delete")), "the Discord session is ended");
    await new Promise((r) => setTimeout(r, 50)); // let the session-token save settle
});

test("stages: build -> test -> fixing on error -> finished when quiet; AI custom status wins", async () => {
    await presence.clearUserPresence("default");
    installFetch((url) => url.endsWith("/headless-sessions") ? json(200, { token: "S9", activities: [] }) : json(204, {}));
    const registered = {};
    const fake = { registerTool(name, _cfg, cb) { registered[name] = cb; } };
    hook.installPresenceToolHook(fake);
    fake.registerTool("execute", {}, async () => ({ content: [] }));
    fake.registerTool("get-data-by-code", {}, async () => ({ content: [], isError: true }));
    fake.registerTool("list-clients", {}, async () => ({ content: [] }));
    const details = () => presence.getPresenceStatus("default").details;

    await registered.execute({});
    assert.equal(details(), "🛠️ Building a script");
    await registered["list-clients"]({});
    assert.equal(details(), "🛠️ Building a script", "housekeeping tools keep the line");
    await registered["get-data-by-code"]({});
    await new Promise((r) => setImmediate(r));
    assert.equal(details(), "🐞 Fixing a bug", "a failed test call means fixing");

    // Quiet for 2 minutes after building/testing -> "Finished a script"
    const realNow = Date.now;
    try {
        Date.now = () => realNow() + 2 * 60_000;
        presence.updateGamePresence("default", { placeId: 1, placeName: "Game" });
        assert.equal(details(), "✅ Finished a script");
        Date.now = () => realNow() + 20 * 60_000;
        presence.updateGamePresence("default", { placeId: 1, placeName: "Game" });
        assert.equal(details(), "Using VoidHub", "finished only stays for a while");
    }
    finally {
        Date.now = realNow;
    }

    // The AI's own status wins over automatic stages until cleared
    presence.setCustomStatus("default", "🛠️ Building Pet Sim auto-farm", null);
    await registered.execute({});
    assert.equal(details(), "🛠️ Building Pet Sim auto-farm");
    presence.setCustomStatus("default", null, null);
    assert.equal(details(), "🛠️ Building a script");
    await presence.clearUserPresence("default");
});

test("clearing while an update is still on its way doesn't leave a stuck status", async () => {
    await presence.clearUserPresence("default");
    calls.length = 0;
    let release;
    installFetch((url, body) => {
        if (url.endsWith("/headless-sessions"))
            return new Promise((r) => { release = () => r(json(200, { token: "LATE", activities: [] })); });
        return json(204, {});
    });
    const p = presence.sendTestPresence("default", "Testing", null);
    await new Promise((r) => setTimeout(r, 20));
    const clearing = presence.clearUserPresence("default"); // clear while the push is in flight
    await new Promise((r) => setTimeout(r, 20));
    assert.equal(calls.filter((c) => c.url.endsWith("/delete")).length, 0, "waits for the in-flight push");
    release();
    await p; await clearing;
    const del = calls.filter((c) => c.url.endsWith("/headless-sessions/delete"));
    assert.equal(del.length, 1);
    assert.equal(del[0].body.token, "LATE", "deletes the session the late push created");
});

test("on startup, a session left by the previous process is ended", async () => {
    await presence.clearUserPresence("default");
    const link = await store.getLink("default");
    await store.saveLink("default", { ...link, sessionToken: "GHOST" });
    calls.length = 0;
    installFetch(() => json(204, {}));
    await presence.clearStaleSessionOnStartup("default");
    const del = calls.filter((c) => c.url.endsWith("/headless-sessions/delete"));
    assert.equal(del.length, 1);
    assert.equal(del[0].body.token, "GHOST");
    assert.equal((await store.getLink("default")).sessionToken, null);
});

test("a phone client that stopped polling counts as out of the game after 20s", async () => {
    const registry = await import("../dist/bridge/handlers/shared/registry.js");
    const id = registry.registerClient({ username: "q", userId: 2, placeId: 777, jobId: "j2", placeName: "Stale Game", transport: "http", mobile: true });
    const entry = registry.getClientById(id);
    entry.lastHttpPoll = Date.now();
    assert.equal(hook.currentGame()?.placeId, 777);
    entry.lastHttpPoll = Date.now() - 25_000; // still inside the registry's 45s grace
    assert.equal(hook.currentGame(), null, "presence treats it as gone");
    registry.unregisterClient(id);
});

test("unlinked users are a silent no-op", async () => {
    await store.deleteLink("default");
    calls.length = 0;
    installFetch(() => { throw new Error("network down"); });
    presence.updateUserPresence("default", "Making a script");
    await new Promise((r) => setTimeout(r, 20));
    assert.equal(calls.filter((c) => c.url.includes("headless")).length, 0);
});
