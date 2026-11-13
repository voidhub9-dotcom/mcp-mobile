import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";

// 1. The MCP tool file exists and registers the "anti-afk" tool.
const toolPath = new URL("../src/tools/impl/clients/anti-afk.ts", import.meta.url);
assert.ok(existsSync(toolPath), "src/tools/impl/clients/anti-afk.ts must exist");
const toolSource = readFileSync(toolPath, "utf8");

assert.match(toolSource, /registerTool\("anti-afk"/, "tool file must register the anti-afk tool");
assert.match(toolSource, /z\s*\.enum\(\s*\[\s*"enable",\s*"disable",\s*"status"\s*\]\s*\)/, "tool must accept enable/disable/status actions");
assert.match(toolSource, /type: "anti-afk"/, "tool must send bridge messages of type anti-afk");

// 2. The connector-side handler binds the matching bridge type.
const handlerPath = new URL("../connector-src/bridge/handlers/anti-afk.luau", import.meta.url);
assert.ok(existsSync(handlerPath), "connector-src/bridge/handlers/anti-afk.luau must exist");
const handlerSource = readFileSync(handlerPath, "utf8");

assert.match(handlerSource, /BindToType\("anti-afk"/, "connector handler must bind the anti-afk bridge type");
assert.match(handlerSource, /"enable"/, "handler must support the enable action");
assert.match(handlerSource, /"disable"/, "handler must support the disable action");
assert.match(handlerSource, /AntiAFK\.Ensure\(\)/, "enable must (re-)connect the Idled handler");
assert.match(handlerSource, /AntiAFK\.Disable\(\)/, "disable must disconnect the Idled handler");
assert.match(handlerSource, /AntiAFK\.Status\(\)/, "status must report the current anti-AFK state");

// 3. The shared controller keeps the Player.Idled / VirtualUser behavior.
const controllerPath = new URL("../connector-src/anti-afk.luau", import.meta.url);
assert.ok(existsSync(controllerPath), "connector-src/anti-afk.luau must exist");
const controllerSource = readFileSync(controllerPath, "utf8");

assert.match(controllerSource, /Idled:Connect/, "controller must connect the Player.Idled signal");
assert.match(controllerSource, /VirtualUser/, "controller must answer Idled with VirtualUser input");
assert.match(controllerSource, /:Disconnect\(\)/, "controller must be able to disconnect the handler");

// 4. init.luau uses the shared controller and passes it to the bridge runtime.
const initSource = readFileSync(new URL("../connector-src/init.luau", import.meta.url), "utf8");
assert.match(initSource, /require\("\.\/anti-afk"\)/, "init.luau must require the shared anti-afk controller");
assert.match(initSource, /AntiAFK = AntiAFK/, "init.luau must pass the controller into the bridge runtime context");

// 5. The handler is registered in the connector's runtime registrar list.
const runtimeSource = readFileSync(new URL("../connector-src/bridge/runtime.luau", import.meta.url), "utf8");
assert.match(runtimeSource, /require\("\.\/handlers\/anti-afk"\)/, "runtime must register the anti-afk handler");

// 6. The tool is wired into the MCP tool registry.
const registrySource = readFileSync(new URL("../src/tools/index.ts", import.meta.url), "utf8");
assert.match(registrySource, /impl\/clients\/anti-afk\.js/, "tool registry must import the anti-afk tool");
assert.match(registrySource, /registerAntiAFK\(server\)/, "tool registry must register the anti-afk tool");

// 7. The compiled output contains the tool (requires `npm run build` first).
const compiledToolPath = new URL("../dist/tools/impl/clients/anti-afk.js", import.meta.url);
assert.ok(existsSync(compiledToolPath), "dist/tools/impl/clients/anti-afk.js must exist after build");
const compiledTool = readFileSync(compiledToolPath, "utf8");
assert.match(compiledTool, /"anti-afk"/, "compiled tool must register the anti-afk tool");
const compiledRegistry = readFileSync(new URL("../dist/tools/index.js", import.meta.url), "utf8");
assert.match(compiledRegistry, /anti-afk\.js/, "compiled registry must include the anti-afk tool");

// 8. The README advertises the tool.
const readme = readFileSync(new URL("../README.md", import.meta.url), "utf8");
assert.match(readme, /anti-afk.*MCP tool.*enable.*disable.*status/s, "README must document the anti-afk tool actions");

console.log("anti-afk tool test passed");
