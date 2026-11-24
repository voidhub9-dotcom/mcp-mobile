import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";

// 1. The MCP tool file exists and registers the "server-hop" tool.
const toolPath = new URL("../src/tools/impl/clients/server-hop.ts", import.meta.url);
assert.ok(existsSync(toolPath), "src/tools/impl/clients/server-hop.ts must exist");
const toolSource = readFileSync(toolPath, "utf8");

assert.match(toolSource, /registerTool\("server-hop"/, "tool file must register the server-hop tool");
assert.match(toolSource, /z\s*\.\s*enum\(\s*\[\s*"hop",\s*"list",\s*"rejoin"\s*\]\s*\)/, "tool must accept hop/list/rejoin actions");
assert.match(toolSource, /type: "get-data-by-code"/, "tool must ride the existing get-data-by-code bridge type");
assert.match(toolSource, /TeleportToPlaceInstance/, "hop payload must teleport via TeleportService");
assert.match(toolSource, /servers\/Public/, "hop payload must fetch the public server list");
assert.match(toolSource, /lowest-ping/, "tool must support server selection by ping");
assert.match(toolSource, /queue_on_teleport/, "tool must queue the connector reload after the hop");

// 2. Both connector code paths already serve the get-data-by-code bridge type
// (server-hop relies on that instead of introducing a new connector handler).
const coreHandlerPath = new URL("../connector-src/bridge/handlers/core.luau", import.meta.url);
assert.ok(existsSync(coreHandlerPath), "connector-src/bridge/handlers/core.luau must exist");
const coreHandlerSource = readFileSync(coreHandlerPath, "utf8");
assert.match(coreHandlerSource, /BindToType\("get-data-by-code"/, "desktop connector must bind get-data-by-code");

const mobileSource = readFileSync(new URL("../connector-src/mobile-connector.luau", import.meta.url), "utf8");
assert.match(mobileSource, /Callbacks\["get-data-by-code"\]/, "mobile connector must register the get-data-by-code callback");

// 3. The tool is wired into the MCP tool registry.
const registrySource = readFileSync(new URL("../src/tools/index.ts", import.meta.url), "utf8");
assert.match(registrySource, /impl\/clients\/server-hop\.js/, "tool registry must import the server-hop tool");
assert.match(registrySource, /registerServerHop\(server\)/, "tool registry must register the server-hop tool");

// 4. The compiled output contains the tool (requires `npm run build` first).
const compiledToolPath = new URL("../dist/tools/impl/clients/server-hop.js", import.meta.url);
assert.ok(existsSync(compiledToolPath), "dist/tools/impl/clients/server-hop.js must exist after build");
const compiledTool = readFileSync(compiledToolPath, "utf8");
assert.match(compiledTool, /"server-hop"/, "compiled tool must register the server-hop tool");
const compiledRegistry = readFileSync(new URL("../dist/tools/index.js", import.meta.url), "utf8");
assert.match(compiledRegistry, /server-hop\.js/, "compiled registry must include the server-hop tool");

// 5. The README advertises the tool.
const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
assert.match(readme, /server-hop/, "README must document the server-hop tool");

console.log("server-hop tool test passed");
