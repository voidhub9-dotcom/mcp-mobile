return function(context, Bridge)
local AntiAFK = context.AntiAFK

Bridge:BindToType("anti-afk", function(data)
    if type(AntiAFK) ~= "table" then
        return {
            action = data.action or "status",
            active = false,
            error = "Anti-AFK controller is unavailable on this connector.",
        }
    end

    local action = data.action or "status"

    if action == "enable" then
        -- Clear the opt-out flag so a re-executed connector also stays protected.
        getgenv().MCP_DisableAntiAFK = nil
        local active = AntiAFK.Ensure()
        return {
            action = "enable",
            active = active,
            message = active
                and "Anti-AFK enabled: Player.Idled handler connected and ready."
                or "Anti-AFK could not be enabled (no LocalPlayer available).",
        }
    elseif action == "disable" then
        AntiAFK.Disable()
        getgenv().MCP_DisableAntiAFK = true
        return {
            action = "disable",
            active = false,
            message = "Anti-AFK disabled: Player.Idled handler disconnected.",
        }
    end

    local status = AntiAFK.Status()
    status.action = "status"
    status.message = status.active
        and "Anti-AFK is active: the Player.Idled handler is connected."
        or "Anti-AFK is inactive: the Player.Idled handler is not connected."
    return status
end)
end
