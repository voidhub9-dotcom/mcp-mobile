import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { describeResponse, sendAndWait, sendFireAndForget, toolTextResponse } from "../../factory.js";
import { maxOutputCharsSchema } from "../../schemas.js";

const PASTE_API = "https://paste-void.lovable.app/api/paste";

async function uploadToPaste(content: string, title: string): Promise<string> {
    const res = await fetch(PASTE_API, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ content, language: "lua", title }),
    });
    if (!res.ok) throw new Error(`paste upload failed: ${res.status}`);
    const json = await res.json() as { rawUrl: string };
    return json.rawUrl;
}

function buildCaptureScript(duration: number, nameFilter: string | undefined): string {
    const filter = nameFilter ? nameFilter.replace(/'/g, "\\'") : "";
    return `
setthreadidentity(8)
local logs = {}
local startTime = os.clock()
local DURATION = ${duration}
local NAME_FILTER = ${nameFilter ? `"${filter}"` : "nil"}

local function escStr(s)
    return tostring(s):gsub('\\\\', '\\\\\\\\'):gsub('"', '\\\\"'):gsub('\\n', '\\\\n'):gsub('\\r', '\\\\r'):gsub('\\t', '\\\\t')
end

local function serialize(v, d)
    d = d or 0
    if d > 4 then return '"[max depth]"' end
    local t = type(v)
    if t == "nil" then return "null"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number" then
        if v ~= v then return '"NaN"' end
        return tostring(v)
    elseif t == "string" then return '"' .. escStr(v) .. '"'
    elseif t == "table" then
        local arr = {}
        for i = 1, #v do arr[i] = serialize(v[i], d + 1) end
        if #arr > 0 then return "[" .. table.concat(arr, ",") .. "]" end
        local kv = {}
        for k, val in pairs(v) do
            if type(k) == "string" or type(k) == "number" then
                table.insert(kv, '"' .. escStr(tostring(k)) .. '":' .. serialize(val, d + 1))
            end
        end
        return "{" .. table.concat(kv, ",") .. "}"
    else
        return '"[' .. t .. ': ' .. escStr(tostring(v)) .. ']"'
    end
end

-- Hook remotes via __namecall
local ok, mt = pcall(getrawmetatable, game)
if not ok then print("[MCP-SPY] getrawmetatable not available"); return end
local oldNamecall = mt.__namecall
pcall(setreadonly, mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "FireServer" or method == "InvokeServer" or method == "FireAllClients" or method == "FireClient" then
        local name = tostring(self.Name or self)
        local match = not NAME_FILTER or name:lower():find(NAME_FILTER:lower(), 1, true)
        if match and #logs < 500 then
            table.insert(logs, {
                name = name,
                method = method,
                t = math.floor((os.clock() - startTime) * 1000),
                args = {...}
            })
        end
    end
    return oldNamecall(self, ...)
end)
pcall(setreadonly, mt, true)

print("[MCP-SPY] Capturing remotes for " .. DURATION .. "s" .. (NAME_FILTER and (" (filter: " .. NAME_FILTER .. ")") or "") .. "...")

task.delay(DURATION, function()
    -- Unhook
    pcall(setreadonly, mt, false)
    mt.__namecall = oldNamecall
    pcall(setreadonly, mt, true)

    -- Build JSON
    local entries = {}
    for _, log in ipairs(logs) do
        local argParts = {}
        for _, a in ipairs(log.args) do
            table.insert(argParts, serialize(a))
        end
        table.insert(entries, string.format(
            '{"name":%s,"method":%s,"t":%d,"args":[%s]}',
            serialize(log.name), serialize(log.method), log.t, table.concat(argParts, ",")
        ))
    end
    local jsonBody = '[' .. table.concat(entries, ',') .. ']'

    -- Upload to paste-void
    local uploadOk, result = pcall(request, {
        Url = "${PASTE_API}",
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = '{"content":' .. serialize(jsonBody) .. ',"language":"json","title":"remote-spy-capture"}'
    })

    if uploadOk and result and result.Body then
        local rawUrl = result.Body:match('"rawUrl":"([^"]+)"')
        if rawUrl then
            print("[MCP-SPY] Results (" .. #logs .. " remotes): " .. rawUrl)
        else
            print("[MCP-SPY] Upload response: " .. tostring(result.Body):sub(1, 300))
        end
    else
        print("[MCP-SPY] Upload failed: " .. tostring(result))
        -- Fallback: print first few logs inline
        print("[MCP-SPY] Inline fallback (" .. #logs .. " captured):")
        for i = 1, math.min(10, #logs) do
            local l = logs[i]
            print(string.format("  [%dms] %s %s", l.t, l.method, l.name))
        end
    end
end)
`;
}

const inputSchema = z.discriminatedUnion("operation", [
    z.object({
        operation: z.literal("list"),
        direction: z
            .enum(["Incoming", "Outgoing", "Both"])
            .describe("Call direction to inspect (default: Both)")
            .optional()
            .default("Both"),
        nameFilter: z
            .string()
            .describe("Case-insensitive substring filter for remote names")
            .optional(),
        limit: z
            .number()
            .describe("Maximum remote entries to return (default: 5, max: 100)")
            .optional()
            .default(5),
        maxCallsPerRemote: z
            .number()
            .describe("Recent calls to include per remote when summaryOnly is false (default: 1, max: 20)")
            .optional()
            .default(1),
        summaryOnly: z
            .boolean()
            .describe("Return names, state, and call counts without argument payloads (default: true)")
            .optional()
            .default(true),
        maxOutputChars: maxOutputCharsSchema,
    }),
    z.object({ operation: z.literal("clear") }),
    z.object({ operation: z.literal("status") }),
    z.object({
        operation: z.literal("inject"),
        preset: z
            .enum(["cobalt"])
            .describe(
                "Named remote spy preset to load. " +
                "'cobalt' fetches Cobalt (gitlab.com/upio/cobalt) via HttpGet inside the executor — " +
                "no source string needed, Roblox downloads it directly."
            )
            .optional(),
        url: z
            .string()
            .describe(
                "URL to fetch the spy script from inside the executor using HttpGet. " +
                "Use this when you have a custom-hosted spy script."
            )
            .optional(),
        source: z
            .string()
            .describe(
                "Raw Luau source of a remote spy script to inject directly. " +
                "Runs at thread identity 8. For Cobalt or large scripts use 'preset' or 'url' instead."
            )
            .optional(),
        maxOutputChars: maxOutputCharsSchema,
    }),
    z.object({
        operation: z.literal("capture"),
        duration: z
            .number()
            .optional()
            .default(10)
            .describe("Seconds to capture remote calls before uploading results to paste-void (default: 10)"),
        nameFilter: z
            .string()
            .optional()
            .describe("Only capture remotes whose name contains this substring (case-insensitive)"),
    }),
]);

export default function register(server: McpServer): void {
    server.registerTool("remote-spy", {
        title: "Inspect remote inventory and activity",
        description:
            "Remote spy tool. The 'operation' field MUST be exactly one of: 'list', 'clear', 'status', 'inject', 'capture'. " +
            "PREFERRED on mobile: operation='capture' — injects a self-contained spy script, captures remotes for N seconds, " +
            "uploads results to paste-void.lovable.app, and prints the rawUrl to console. " +
            "Read the URL from get-console-output then fetch it. " +
            "Fallback workflow: (1) operation='inject' preset='cobalt'. " +
            "(2) operation='list' summaryOnly=true limit=5. " +
            "(3) operation='list' nameFilter='<name>' summaryOnly=false. " +
            "(4) operation='clear' to reset. operation='status' to check active spy.",
        inputSchema,
    }, async (input) => {
        if (input.operation === "capture") {
            const { duration, nameFilter } = input;
            const script = buildCaptureScript(duration, nameFilter);

            let rawUrl: string;
            try {
                rawUrl = await uploadToPaste(script, "mcp-remote-spy");
            } catch (err) {
                return toolTextResponse(`Failed to upload capture script to paste-void: ${err}`, {}, true);
            }

            const loadstringSource = `setthreadidentity(8)\nloadstring(game:HttpGet("${rawUrl}"))()`;

            return sendFireAndForget({
                type: "execute",
                data: { source: loadstringSource },
                successMessage:
                    `Remote spy capture script injected (duration: ${duration}s${nameFilter ? `, filter: ${nameFilter}` : ""}). ` +
                    `After ${duration}s, use get-console-output and look for a line starting with "[MCP-SPY] Results" — ` +
                    `it contains the paste-void rawUrl with all captured remote calls.`,
            });
        }

        const maxOutputChars = (input.operation === "list" || input.operation === "inject")
            ? input.maxOutputChars
            : undefined;
        return sendAndWait({
            type: "remote-spy",
            data: input as Record<string, unknown>,
            maxOutputChars,
            stampClient: true,
            truncationHint: "Rerun remote-spy list with summaryOnly=true, a nameFilter, a lower limit, or fewer calls per remote.",
            failureMessage: (response) => "Failed to use remote spy: " + describeResponse(response),
        });
    });
}
