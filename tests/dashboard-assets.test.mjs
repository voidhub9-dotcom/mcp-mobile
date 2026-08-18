import assert from "node:assert/strict";
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";

// index.html pulls its own stylesheets and scripts by URL. Nothing previously
// checked that a route actually answers those URLs, so a referenced asset could
// go unserved and the browser would quietly receive the plain-text server
// fallback instead — parsing "MCP Server Running" as JavaScript and taking the
// rest of that script with it.
const dashboardDir = fileURLToPath(new URL("../src/http/assets/dashboard/", import.meta.url));
const routesDir = fileURLToPath(new URL("../src/http/routes/(dashboard)/", import.meta.url));
const html = readFileSync(`${dashboardDir}index.html`, "utf8");

const collect = (pattern) => {
    const found = [];
    for (const match of html.matchAll(pattern)) found.push(match[1]);
    return found;
};

// Local references only: CDN and data URLs are out of scope here.
const isLocal = (ref) => !/^(https?:)?\/\//.test(ref) && !ref.startsWith("data:");

const references = [
    ...collect(/<link[^>]+href="([^"]+)"/g),
    ...collect(/<script[^>]+src="([^"]+)"/g),
].filter(isLocal);

assert.ok(references.length >= 5, "expected the dashboard to reference several local assets");

for (const ref of references) {
    const name = ref.replace(/^\.?\//, "");

    assert.ok(
        existsSync(`${dashboardDir}${name}`),
        `index.html references ${ref} but no such asset exists in src/http/assets/dashboard/`,
    );

    // dashboard.js is loaded as a module and pulls its own siblings in turn; the
    // route layer still has to expose every one of them at the referenced path.
    assert.ok(
        existsSync(`${routesDir}${name}.ts`),
        `index.html references ${ref} but src/http/routes/(dashboard)/${name}.ts does not exist, ` +
            "so the server will answer that URL with its plain-text fallback",
    );
}

// Assets imported by dashboard.js rather than named in the HTML.
const dashboardJs = readFileSync(`${dashboardDir}dashboard.js`, "utf8");
for (const match of dashboardJs.matchAll(/^import\s[^'"]*['"]\.\/([^'"]+)['"]/gm)) {
    const name = match[1];
    assert.ok(
        existsSync(`${routesDir}${name}.ts`),
        `dashboard.js imports ./${name} but no route serves it`,
    );
}

// Routes must declare a JavaScript content type, or a module import is rejected.
for (const name of references.filter((r) => r.endsWith(".js"))) {
    const route = readFileSync(`${routesDir}${name.replace(/^\.?\//, "")}.ts`, "utf8");
    assert.match(
        route,
        /application\/javascript/,
        `${name} must be served with a JavaScript content type`,
    );
}

console.log(`dashboard asset test passed (${references.length} local references checked)`);
