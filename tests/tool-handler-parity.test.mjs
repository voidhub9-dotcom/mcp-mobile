import assert from "node:assert/strict";
import test from "node:test";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "..");

/**
 * Every message type the MCP server can send to a connected Roblox client
 * (via sendAndWait / tool factories) must have a matching handler on BOTH
 * client code paths:
 *   - desktop: connector-src/bridge/handlers/*.luau (Bridge:BindToType)
 *   - mobile:  connector-src/mobile-connector.luau (Callbacks[...])
 * Server-side tools (list-clients, set-active-client, script-grep, ...) never
 * reach a client and are excluded by only scanning for sendAndWait payloads.
 */

const TOOL_IMPL_DIR = path.join(repoRoot, "src", "tools", "impl");

function collectClientBoundMessageTypes() {
  const types = new Set();
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
        continue;
      }
      if (!entry.name.endsWith(".ts")) continue;
      const source = fs.readFileSync(full, "utf8");
      const sendWaits = source.matchAll(/sendAndWait\(\s*\{\s*type:\s*"([a-z0-9-]+)"/g);
      for (const match of sendWaits) {
        types.add(match[1]);
      }
    }
  };
  walk(TOOL_IMPL_DIR);
  return [...types].sort();
}

function collectDesktopHandlerTypes() {
  const handlersDir = path.join(repoRoot, "connector-src", "bridge", "handlers");
  const types = new Set();
  const walk = (dir) => {
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(full);
        continue;
      }
      if (!entry.name.endsWith(".luau")) continue;
      const source = fs.readFileSync(full, "utf8");
      const bindings = source.matchAll(/BindToType\w*\(\s*"([a-z0-9-]+)"/g);
      for (const match of bindings) {
        types.add(match[1]);
      }
    }
  };
  walk(handlersDir);
  return types;
}

function collectMobileHandlerTypes() {
  const source = fs.readFileSync(
    path.join(repoRoot, "connector-src", "mobile-connector.luau"),
    "utf8",
  );
  const types = new Set();
  for (const match of source.matchAll(/Callbacks\["([a-z0-9-]+)"\]\s*=/g)) {
    types.add(match[1]);
  }
  return types;
}

test("every client-bound tool message type has a desktop connector handler", () => {
  const clientBound = collectClientBoundMessageTypes();
  assert.ok(clientBound.length >= 15, `expected a meaningful set of client-bound types, got ${clientBound.length}`);

  const desktop = collectDesktopHandlerTypes();
  const missing = clientBound.filter((type) => !desktop.has(type));
  assert.deepEqual(
    missing,
    [],
    `message types with no Bridge:BindToType handler in connector-src/bridge/handlers (desktop connector would time out): ${missing.join(", ")}`,
  );
});

test("every client-bound tool message type has a mobile connector handler", () => {
  const clientBound = collectClientBoundMessageTypes();
  const mobile = collectMobileHandlerTypes();
  const missing = clientBound.filter((type) => !mobile.has(type));
  assert.deepEqual(
    missing,
    [],
    `message types with no Callbacks[...] handler in connector-src/mobile-connector.luau (mobile connector would time out): ${missing.join(", ")}`,
  );
});

test("root mobile-connector.luau stays in sync with connector-src/mobile-connector.luau", () => {
  const root = fs.readFileSync(path.join(repoRoot, "mobile-connector.luau"), "utf8");
  const src = fs.readFileSync(path.join(repoRoot, "connector-src", "mobile-connector.luau"), "utf8");
  assert.equal(root, src, "mobile-connector.luau (root) must match connector-src/mobile-connector.luau");
});
