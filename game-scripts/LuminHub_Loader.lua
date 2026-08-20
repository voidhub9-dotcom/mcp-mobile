-- Lumin Hub autoloader (Steal An Egg)
-- Put this in your executor's auto-execute list so the hub comes back
-- by itself after a kick, rejoin, or server hop.
if game.PlaceId ~= 107778070777162 then return end
task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(3)
    getgenv().LuminHubSource =
        "https://raw.githubusercontent.com/voidhub9-dotcom/mcp-mobile/claude/mcp-roblox-connection-ckg4ii/game-scripts/Steal_An_Egg_LuminHub.lua"
    local ok, body = pcall(function() return game:HttpGet(getgenv().LuminHubSource) end)
    if not ok then warn("[LuminHub] loader fetch failed: " .. tostring(body)) return end
    local chunk, err = loadstring(body)
    if not chunk then warn("[LuminHub] loader compile failed: " .. tostring(err)) return end
    local ran, rerr = pcall(chunk)
    if not ran then warn("[LuminHub] loader run failed: " .. tostring(rerr)) end
end)
