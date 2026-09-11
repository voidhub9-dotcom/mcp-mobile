return function(_context, Bridge)
    Bridge:BindToType("clear-remote-spy-logs", function(data)
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
        end

        error("Invalid remote-spy operation: " .. tostring(operation))
    end)
end
