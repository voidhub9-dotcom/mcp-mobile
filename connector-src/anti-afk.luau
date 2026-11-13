-- Shared anti-AFK controller.
-- Keeps the local player from being kicked for idling by answering the
-- Player.Idled signal with VirtualUser input. Used by init.luau (startup
-- default) and the "anti-afk" bridge handler (MCP tool control).

local AntiAFK = {}

local function getState()
    local state = getgenv().MCP_AntiAFKState
    if type(state) ~= "table" then
        state = {}
        getgenv().MCP_AntiAFKState = state
    end
    return state
end

local function isConnected(state)
    if state.Connection == nil then
        return false
    end
    local ok, connected = pcall(function()
        return state.Connection.Connected
    end)
    if ok and connected == true then
        return true
    end
    -- Dead connection (server hop / executor reload): forget it so Ensure can re-connect.
    state.Connection = nil
    return false
end

local function onIdled()
    pcall(function()
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end

-- Ensures the Player.Idled anti-kick handler is connected, re-connecting it
-- when needed. Returns true when anti-AFK is active.
function AntiAFK.Ensure()
    local state = getState()
    if isConnected(state) then
        return true
    end

    local ok, connection = pcall(function()
        local player = game:GetService("Players").LocalPlayer
        if not player then
            return nil
        end
        return player.Idled:Connect(onIdled)
    end)

    if ok and connection ~= nil then
        state.Connection = connection
        return true
    end
    return false
end

-- Disconnects the Player.Idled handler. Returns true when no handler is left running.
function AntiAFK.Disable()
    local state = getState()
    if state.Connection ~= nil then
        pcall(function()
            state.Connection:Disconnect()
        end)
        state.Connection = nil
    end
    return true
end

-- Reports whether anti-AFK is currently protecting the session.
function AntiAFK.Status()
    local state = getgenv().MCP_AntiAFKState
    local active = false
    if type(state) == "table" then
        active = isConnected(state)
    end
    return {
        active = active,
        disabledByConfig = getgenv().MCP_DisableAntiAFK == true,
    }
end

return AntiAFK
