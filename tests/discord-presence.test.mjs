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
        assert.equal(act.name, "Void Hub RPC");
        assert.equal(act.type, 0);
        assert.equal(act.details, "Making a script");
        assert.equal(act.state, "Connected via Void Hub MCP");
        assert.equal(act.assets.large_image, "void_logo");
        assert.equal(act.assets.large_text, "Void Hub MCP");
        assert.deepEqual(act.buttons, [{ label: "Get Void Hub", url: "https://example.test/get" }]);
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

test("unlinked users are a silent no-op", async () => {
    await store.deleteLink("default");
    calls.length = 0;
    installFetch(() => { throw new Error("network down"); });
    presence.updateUserPresence("default", "Making a script");
    await new Promise((r) => setTimeout(r, 20));
    assert.equal(calls.filter((c) => c.url.includes("headless")).length, 0);
});
