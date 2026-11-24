import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";

// 1. The MCP tool file exists and registers the "phone-shell" tool.
const toolPath = new URL("../src/tools/impl/clients/phone-shell.ts", import.meta.url);
assert.ok(existsSync(toolPath), "src/tools/impl/clients/phone-shell.ts must exist");
const toolSource = readFileSync(toolPath, "utf8");

assert.match(toolSource, /registerTool\("phone-shell"/, "tool file must register the phone-shell tool");
assert.match(toolSource, /teleport across games|across Roblox GAMES|cross-creator teleports/, "tool description must explain the cross-game use case");
assert.match(toolSource, /roblox:\/\/placeId=/, "tool description must mention the deep link usage");

// 2. The tool must NOT ride the bridge sendAndWait helper: it targets Termux
// agents, and the connector parity test only knows about in-game handlers.
assert.doesNotMatch(toolSource, /sendAndWait\(\s*\{\s*type:\s*"/,
    "phone-shell must dispatch directly (SendArbitraryDataToClient), not via bridge sendAndWait");
assert.match(toolSource, /SendArbitraryDataToClient\(/, "phone-shell must dispatch via SendArbitraryDataToClient");
assert.match(toolSource, /GetResponseOfIdFromClient\(/, "phone-shell must wait via GetResponseOfIdFromClient");
assert.match(toolSource, /phone-shell/, "phone-shell message type must match the agent handler");

// 3. The agent registration route exists, enforces the TERMUX_TOKEN secret,
// and registers clients carrying the phone-shell capability.
const registerRoutePath = new URL("../src/http/routes/termux/register.ts", import.meta.url);
assert.ok(existsSync(registerRoutePath), "src/http/routes/termux/register.ts must exist");
const registerRoute = readFileSync(registerRoutePath, "utf8");
assert.match(registerRoute, /TERMUX_TOKEN/, "route must check the TERMUX_TOKEN environment variable");
assert.match(registerRoute, /timingSafeEqual/, "route must compare tokens in constant time");
assert.match(registerRoute, /phone-shell/, "route must register the phone-shell capability");
assert.match(registerRoute, /sessionId: "termux-agent"/, "route must reuse a stable session id");

// 4. The bridge serves the agent script at /termux/agent.sh.
const agentRoutePath = new URL("../src/http/routes/termux/agent.sh.ts", import.meta.url);
assert.ok(existsSync(agentRoutePath), "src/http/routes/termux/agent.sh.ts must exist");
const agentRoute = readFileSync(agentRoutePath, "utf8");
assert.match(agentRoute, /termux\/agent\.sh/, "route must serve termux/agent.sh");

// 5. The agent script exists and speaks the bridge protocol.
const agentPath = new URL("../termux/agent.sh", import.meta.url);
assert.ok(existsSync(agentPath), "termux/agent.sh must exist");
const agentSource = readFileSync(agentPath, "utf8");
assert.match(agentSource, /\/termux\/register/, "agent must register via /termux/register");
assert.match(agentSource, /\/poll\?clientId=/, "agent must long-poll /poll");
assert.match(agentSource, /\/respond/, "agent must answer via /respond");
assert.match(agentSource, /phone-shell/, "agent must handle phone-shell messages");
assert.match(agentSource, /bash", "-lc"/, "agent must run commands through bash -lc");
assert.match(agentSource, /exit: /, "agent must report the command exit code");
assert.match(agentSource, /MCP_AGENT_TOKEN/, "agent must read MCP_AGENT_TOKEN");

// 6. The tool is wired into the MCP tool registry.
const registrySource = readFileSync(new URL("../src/tools/index.ts", import.meta.url), "utf8");
assert.match(registrySource, /impl\/clients\/phone-shell\.js/, "tool registry must import the phone-shell tool");
assert.match(registrySource, /registerPhoneShell\(server\)/, "tool registry must register the phone-shell tool");

// 7. The compiled output contains the tool and the route (requires `npm run build` first).
const compiledToolPath = new URL("../dist/tools/impl/clients/phone-shell.js", import.meta.url);
assert.ok(existsSync(compiledToolPath), "dist/tools/impl/clients/phone-shell.js must exist after build");
const compiledTool = readFileSync(compiledToolPath, "utf8");
assert.match(compiledTool, /"phone-shell"/, "compiled tool must register the phone-shell tool");
const compiledRegistry = readFileSync(new URL("../dist/tools/index.js", import.meta.url), "utf8");
assert.match(compiledRegistry, /phone-shell\.js/, "compiled registry must include the phone-shell tool");
const compiledRegisterRoute = new URL("../dist/http/routes/termux/register.js", import.meta.url);
assert.ok(existsSync(compiledRegisterRoute), "dist/http/routes/termux/register.js must exist after build");

// 8. The README advertises the agent.
const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
assert.match(readme, /phone-shell/, "README must document the phone-shell tool");

console.log("phone-shell tool test passed");
