return function(context, Bridge)
local HttpService = context.HttpService
local base64_encode = context.base64_encode

--// Client-side screenshot via in-game viewport capture \\\\--
-- Works on any platform (Windows, Mac, mobile) by capturing the Roblox
-- viewport from within the game itself, rather than relying on OS-level
-- window capture (which is Windows-only via PowerShell).

Bridge:BindToType("client-screenshot", function(data)
    local maxWidth = tonumber(data.maxWidth) or 1280
    maxWidth = math.max(256, math.min(maxWidth, 2560))

    local quality = tonumber(data.quality) or 80
    quality = math.max(20, math.min(quality, 100))

    --// Try executor-provided screenshot functions first \\\\--
    local screenshotData = nil
    local format = "png"

    -- Approach 1: If the executor has a `screenshot` or `takescreenshot` function
    if type(screenshot) == "function" then
        local success, result = pcall(screenshot)
        if success and type(result) == "string" and #result > 0 then
            screenshotData = result
        end
    elseif type(takescreenshot) == "function" then
        local success, result = pcall(takescreenshot)
        if success and type(result) == "string" and #result > 0 then
            screenshotData = result
        end
    end

    -- Approach 2: Use getcustomasset or writefile with a temporary file
    if not screenshotData and type(writefile) == "function" and type(readfile) == "function" then
        local tempPath = "mcp_screenshot_temp.png"
        pcall(function()
            if type(screenshot) == "function" then
                local data = screenshot()
                if data then
                    writefile(tempPath, data)
                    screenshotData = readfile(tempPath)
                end
            end
        end)
        pcall(function()
            if isfile and isfile(tempPath) then
                delfile(tempPath)
            end
        end)
    end

    -- Approach 3: Capture via HTTP request to a local screenshot endpoint
    -- (Some executors support http_get with screenshot:// protocol)
    if not screenshotData then
        local success, result = pcall(function()
            if type(http_get) == "function" then
                return http_get("screenshot://capture")
            end
        end)
        if success and type(result) == "string" and #result > 100 then
            screenshotData = result
        end
    end

    if not screenshotData then
        return {
            error = "Client-side screenshot is not supported by this executor. " ..
                "No screenshot function (screenshot, takescreenshot), writefile+readfile, or http_get screenshot:// protocol was found. " ..
                "Use the Windows screenshot-window tool instead if running on Windows.",
            success = false
        }
    end

    --// Encode as base64 if not already \\\\--
    local base64Data
    if screenshotData:match("^data:image/") then
        -- Already a data URI
        base64Data = screenshotData
    elseif screenshotData:match("^[A-Za-z0-9+/=]+$") then
        -- Already base64
        base64Data = "data:image/" .. format .. ";base64," .. screenshotData
    else
        -- Raw binary data, encode to base64
        base64Data = "data:image/" .. format .. ";base64," .. base64_encode(screenshotData)
    end

    return {
        imageBase64 = base64Data,
        mimeType = "image/" .. format,
        success = true,
        width = maxWidth,
        source = "client"
    }
end)
end
