return function(_context, Bridge)
    Bridge:BindToType("clear-remote-spy-logs", function(data)
        local customSpy = getgenv().MCP_CustomRemoteSpy
        if customSpy and type(customSpy.clear) == "function" then
            pcall(customSpy.clear)
            return {
                status = "ok",
                message = "Custom remote spy logs cleared.",
            }
        end
        if getgenv().MCP_RemoteMonitor then
            return {
                status = "no_op",
                message = "Read-only Remote Monitor has no stored call payloads to clear."
            }
        end
        error("Remote Monitor is not initialised. Call ensure-remote-spy first.")
    end)

    Bridge:BindToType("remote-spy", function(data)
        Bridge.Callbacks["ensure-remote-spy"]({})

        local operation = data.operation
        if operation == "status" then
            local customSpy = getgenv().MCP_CustomRemoteSpy
            if customSpy then
                local spyType = customSpy.type or "custom"
                local statusInfo = {}
                if type(customSpy.status) == "function" then
                    pcall(function() statusInfo = customSpy.status() or {} end)
                end
                return {
                    status = "ready",
                    mode = spyType,
                    scans = statusInfo.scans or 0,
                    lastScanAt = statusInfo.lastScanAt or nil,
                    message = "Custom remote spy (" .. spyType .. ") is active and intercepting.",
                }
            end
            if getgenv().Hydroxide then
                return {
                    status = "ready",
                    mode = "hydroxide",
                    scans = 0,
                    lastScanAt = nil,
                    message = "Hydroxide remote spy detected.",
                }
            end
            if getgenv().RemoteSpy or getgenv().RS then
                return {
                    status = "ready",
                    mode = "generic_spy",
                    scans = 0,
                    lastScanAt = nil,
                    message = "Generic remote spy detected.",
                }
            end
            local monitor = getgenv().MCP_RemoteMonitor
            return {
                status = monitor and "ready" or "unavailable",
                mode = "read_only_inventory",
                scans = monitor and monitor.scans or 0,
                lastScanAt = monitor and monitor.lastScanAt or nil,
                message = "Remote Monitor lists public Remote instances without intercepting or changing game traffic.",
            }
        elseif operation == "list" then
            return Bridge.Callbacks["get-remote-spy-logs"]({
                direction = data.direction,
                remoteNameFilter = data.nameFilter,
                limit = data.limit,
                maxCallsPerRemote = data.maxCallsPerRemote,
                summaryOnly = data.summaryOnly,
            })
        elseif operation == "clear" then
            return Bridge.Callbacks["clear-remote-spy-logs"]({})
        elseif operation == "inject" then
            local source = data.source
            if type(source) ~= "string" or source == "" then
                error("inject requires a non-empty 'source' string.")
            end
            -- Clear any previous custom spy before injecting
            getgenv().MCP_CustomRemoteSpy = nil
            local ok, err = pcall(function()
                setthreadidentity(8)
                loadstring(source)()
            end)
            if not ok then
                return {
                    status = "error",
                    message = "Custom remote spy script failed: " .. tostring(err),
                }
            end
            -- Check for standard MCP interface
            local injected = getgenv().MCP_CustomRemoteSpy
            if injected then
                return {
                    status = "injected",
                    mode = injected.type or "custom",
                    message = "Custom remote spy injected and active.",
                }
            end
            -- Check for known spy bootstraps
            if getgenv().Hydroxide then
                return {
                    status = "injected",
                    mode = "hydroxide",
                    message = "Script ran — Hydroxide detected.",
                }
            end
            if getgenv().RemoteSpy or getgenv().RS then
                return {
                    status = "injected",
                    mode = "generic_spy",
                    message = "Script ran — generic remote spy detected.",
                }
            end
            return {
                status = "injected",
                mode = "unknown",
                message = "Script executed. No standard spy interface detected in getgenv(). Use 'list' to verify.",
            }
        end

        error("Invalid remote-spy operation: " .. tostring(operation))
    end)
end
