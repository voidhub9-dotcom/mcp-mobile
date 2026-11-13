import type { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { describeResponse, sendAndWait } from "../../factory.js";
import { maxOutputCharsSchema, threadContextSchema } from "../../schemas.js";
const inputSchema = z.object({
    operation: z.enum(["scan", "hook", "capture", "dump"]).describe("scan: find encrypted remotes and their decryption functions; hook: install hooks on specific remotes to capture decrypted args; capture: read captured data from hooked remotes; dump: dump all remote metadata and detected encryption patterns"),
    remoteName: z.string().describe("Exact remote name to hook (required for hook/capture operations). Use scan first to discover candidates.").optional(),
    remotePath: z.string().describe("Instance path to the remote (e.g. game.ReplicatedStorage.Events.SomeRemote). Alternative to remoteName.").optional(),
    direction: z.enum(["Incoming", "Outgoing", "Both"]).describe("Direction to hook (default: Both)").optional().default("Both"),
    duration: z.number().min(1).max(60).describe("How long to capture remote calls in seconds (default: 10, max: 60). Only for hook operation.").optional().default(10),
    threadContext: threadContextSchema,
    timeout: z.number().describe("Timeout in ms for the response (default: 15000, max: 120000)").optional().default(15e3),
    maxOutputChars: maxOutputCharsSchema
});
const SCAN_CODE = `
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local results = {
  remotes = {},
  encryptedRemotes = {},
  decryptionFunctions = {},
  summary = "",
}

local function isEncryptedName(name)
  if not name or #name == 0 then return false end
  if name:match("^[%w%-_]+$") and #name <= 30 then return false end
  if #name > 40 then return true end
  if name:match("[^%w%-_]") and not name:match("^[%w_]+$") then return true end
  local hasUpper = name:match("[A-Z]")
  local hasLower = name:match("[a-z]")
  local hasDigit = name:match("[0-9]")
  if hasUpper and hasLower and hasDigit and #name > 15 then
    if not name:match("[aeiouAEIOU]") then return true end
  end
  if name:match("^%x+$") and #name >= 16 then return true end
  if name:match("^[A-Za-z0-9+/=]+$") and #name >= 20 and name:sub(-1,-1) == "=" then return true end
  return false
end

local function scanInstance(root, depth)
  if depth > 6 then return end
  for _, child in ipairs(root:GetChildren()) do
    pcall(function()
      if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        local name = child.Name
        local info = {
          name = name,
          className = child.ClassName,
          path = child:GetFullName(),
          encrypted = isEncryptedName(name),
        }
        table.insert(results.remotes, info)
        if info.encrypted then
          table.insert(results.encryptedRemotes, info)
        end
      end
    end)
    scanInstance(child, depth + 1)
  end
end

pcall(function()
  for _, svc in ipairs({ReplicatedStorage, Workspace, game:GetService("Players")}) do
    scanInstance(svc, 0)
  end
end)

if type(getscripts) == "function" then
  local keywords = {"decrypt", "encrypt", "decode", "encode", "cipher", "xor", "base64", "byte", "char", "hash"}
  local scripts = getscripts()
  local found = {}

  for _, scr in ipairs(scripts) do
    pcall(function()
      local src = ""
      if type(decompile) == "function" then
        src = decompile(scr) or ""
      elseif type(getscriptbytecode) == "function" then
        local bc = getscriptbytecode(scr)
        if bc then src = tostring(bc) end
      end

      if src and #src > 0 then
        for _, kw in ipairs(keywords) do
          if src:lower():find(kw, 1, true) then
            local lineNum = 1
            local lineStart = 1
            for i = 1, #src do
              if src:sub(i, i) == "\\n" then
                local line = src:sub(lineStart, i - 1)
                if line:lower():find(kw, 1, true) then
                  local shortLine = line:sub(1, 200)
                  local key = scr.Name .. ":" .. kw
                  if not found[key] then
                    found[key] = true
                    table.insert(results.decryptionFunctions, {
                      script = scr.Name,
                      path = scr:GetFullName(),
                      keyword = kw,
                      line = shortLine,
                    })
                  end
                end
                lineNum = lineNum + 1
                lineStart = i + 1
              end
            end
          end
        end
      end
    end)
  end
end

local encCount = #results.encryptedRemotes
local totalRemotes = #results.remotes
local decFuncs = #results.decryptionFunctions

results.summary = string.format(
  "Found %d remotes (%d appear encrypted/obfuscated). Found %d potential decryption functions.",
  totalRemotes, encCount, decFuncs
)

return HttpService:JSONEncode(results)
`;
function hookCode(remoteName: string | undefined, remotePath: string | undefined, direction: string | undefined, duration: number): string {
    const dir = direction || "Both";
    const safeDuration = Math.min(Math.max(Number.isFinite(duration) ? duration : 10, 1), 60);
    return `
local HttpService = game:GetService("HttpService")
local duration = ${safeDuration}
local direction = "${dir}"
local remoteName = ${remoteName ? JSON.stringify(remoteName) : "nil"}
local remotePath = ${remotePath ? JSON.stringify(remotePath) : "nil"}

local target = nil
if remotePath then
  pcall(function()
    local obj = game
    for part in remotePath:gmatch("[^.]+") do
      if part == "game" then obj = game
      else obj = obj[part] or obj:FindFirstChild(part) end
    end
    target = obj
  end)
elseif remoteName then
  local function findRemote(root, depth)
    if depth > 8 then return nil end
    for _, child in ipairs(root:GetChildren()) do
      if child.Name == remoteName and (child:IsA("RemoteEvent") or child:IsA("RemoteFunction")) then
        return child
      end
      local found = findRemote(child, depth + 1)
      if found then return found end
    end
    return nil
  end
  for _, svc in ipairs({game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game}) do
    target = findRemote(svc, 0)
    if target then break end
  end
end

if not target then
  return HttpService:JSONEncode({error = "Remote not found"})
end

-- Persistent capture store so the "capture" operation can read hooks later.
local store = getgenv().MCP_RemoteCaptures
if type(store) ~= "table" then
  store = {}
  getgenv().MCP_RemoteCaptures = store
end
local captures = store[target:GetFullName()]
if type(captures) ~= "table" then
  captures = {}
  store[target:GetFullName()] = captures
end

local hookName = target.Name
local hookPath = target:GetFullName()
local hookClass = target.ClassName

local function captureCall(directionLabel, ...)
  -- select('#', ...) keeps nil holes in the argument list; ipairs would stop at the first nil.
  local n = select('#', ...)
  local safeArgs = {}
  for i = 1, n do
    local arg = select(i, ...)
    local ok, encoded = pcall(function()
      if arg == nil then
        return "<nil>"
      elseif type(arg) == "table" then
        return HttpService:JSONEncode(arg)
      else
        return tostring(arg)
      end
    end)
    safeArgs[i] = ok and encoded or "<unserializable>"
  end

  table.insert(captures, {
    direction = directionLabel,
    args = safeArgs,
    time = os.time(),
  })
end

if target:IsA("RemoteEvent") then
  if direction == "Incoming" or direction == "Both" then
    target.OnClientEvent:Connect(function(...)
      captureCall("Incoming", ...)
    end)
  end
elseif target:IsA("RemoteFunction") then
  if direction == "Incoming" or direction == "Both" then
    pcall(function()
      local oldInvoke = target.OnClientInvoke
      target.OnClientInvoke = function(...)
        captureCall("Incoming", ...)
        if oldInvoke then return oldInvoke(...) end
      end
    end)
  end
end

-- Outgoing hooks (FireServer / InvokeServer) require executor function hooking.
if direction == "Outgoing" or direction == "Both" then
  if hookmetamethod then
    pcall(function()
      local oldNamecall
      oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod and getnamecallmethod() or nil
        if self == target and (method == "FireServer" or method == "InvokeServer") then
          captureCall("Outgoing", ...)
        end
        return oldNamecall(self, ...)
      end)
    end)
  elseif hookfunction then
    pcall(function()
      local originalMethod = target:IsA("RemoteEvent") and target.FireServer or target.InvokeServer
      if originalMethod then
        hookfunction(originalMethod, function(...)
          captureCall("Outgoing", ...)
          return originalMethod(...)
        end)
      end
    end)
  end
end

task.wait(duration)

local result = {
  remoteName = hookName,
  remotePath = hookPath,
  remoteClass = hookClass,
  captureCount = #captures,
  captures = captures,
}

return HttpService:JSONEncode(result)
`;
}
const CAPTURE_CODE = `
local HttpService = game:GetService("HttpService")

local store = getgenv().MCP_RemoteCaptures
if type(store) ~= "table" then
  return HttpService:JSONEncode({error = "No active hooks. Use the hook operation first."})
end

local total = 0
for _, remoteCaptures in pairs(store) do
  total = total + #remoteCaptures
end
if total == 0 then
  return HttpService:JSONEncode({error = "Hooks are active but no remote calls have been captured yet."})
end

return HttpService:JSONEncode({totalCaptures = total, remotes = store})
`;
const DUMP_CODE = `
local HttpService = game:GetService("HttpService")

local results = { remotes = {}, total = 0 }

local function scan(root, depth)
  if depth > 8 then return end
  for _, child in ipairs(root:GetChildren()) do
    pcall(function()
      if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
        local name = child.Name
        local hasVowels = name:match("[aeiouAEIOU]")
        local allAlpha = name:match("^%a+$")
        local hasDigit = name:match("[0-9]")
        local length = #name

        table.insert(results.remotes, {
          name = name,
          class = child.ClassName,
          path = child:GetFullName(),
          length = length,
          suspicious = (not hasVowels and length > 8) or (length > 30) or (hasDigit and allAlpha == nil and length > 15),
        })
      end
    end)
    scan(child, depth + 1)
  end
end

for _, svc in ipairs({game:GetService("ReplicatedStorage"), game:GetService("Workspace"), game:GetService("Players")}) do
  pcall(function() scan(svc, 0) end)
end

results.total = #results.remotes
return HttpService:JSONEncode(results)
`;
function register(server: McpServer): void {
    server.registerTool("decrypt-remote", {
        title: "Decrypt and analyze encrypted Roblox remotes",
        description: "Find, hook, and capture encrypted/obfuscated RemoteEvents and RemoteFunctions. scan: discovers remotes and detects encryption patterns + decryption functions in scripts. hook: installs hooks on a specific remote to capture decrypted arguments for a duration. capture: reads captured data from active hooks. dump: lists all remotes with metadata. Use scan first to identify encrypted remotes and their decryption functions.",
        inputSchema
    }, async (input: z.infer<typeof inputSchema>) => {
        let code;
        switch (input.operation) {
            case "scan":
                code = SCAN_CODE;
                break;
            case "hook":
                if (!input.remoteName && !input.remotePath) {
                    return {
                        content: [{ type: "text", text: "Error: remoteName or remotePath is required for the hook operation. Use scan first to discover remotes." }],
                        isError: true
                    };
                }
                code = hookCode(input.remoteName, input.remotePath, input.direction, input.duration);
                break;
            case "capture":
                code = CAPTURE_CODE;
                break;
            case "dump":
                code = DUMP_CODE;
                break;
            default:
                return {
                    content: [{ type: "text", text: `Unknown operation: ${input.operation}` }],
                    isError: true
                };
        }
        const clampedTimeout = Math.min(Math.max(input.timeout, 1e3), 12e4);
        // The hook operation waits out the full capture duration client-side, so the
        // response timeout must always cover it (plus dispatch overhead) or the call
        // would time out even though the hook is working.
        const effectiveTimeout = input.operation === "hook"
            ? Math.min(Math.max(clampedTimeout, (input.duration ?? 10) * 1000 + 5000), 12e4)
            : clampedTimeout;
        return sendAndWait({
            type: "get-data-by-code",
            data: { source: `setthreadidentity(${input.threadContext});${code}` },
            timeoutMs: effectiveTimeout,
            maxOutputChars: input.maxOutputChars,
            stampClient: true,
            truncationHint: "Narrow your scan with a specific remote name or reduce the capture duration.",
            failureMessage: (response) => "Failed to decrypt remote: " + describeResponse(response)
        });
    });
}
export { register as default };
