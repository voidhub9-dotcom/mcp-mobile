return function(_context, Bridge)
    Bridge:BindToType("ensure-remote-spy", function(data)
        local monitor = getgenv().MCP_RemoteMonitor
        if monitor then
            return {
                status = "ready",
                message = "Remote Monitor is ready."
            }
        end

        -- This monitor intentionally has no external loader and does not hook,
        -- block, replay, or invoke remotes. It is reliable on restricted/mobile
        -- executors because it only inventories public Remote instances.
        getgenv().MCP_RemoteMonitor = {
            startedAt = os.time(),
            scans = 0,
            lastScanAt = nil,
        }
        return {
            status = "ready",
            message = "Read-only Remote Monitor is ready."
        }
    end)

    Bridge:BindToType("get-remote-spy-logs", function(data)
        local monitor = getgenv().MCP_RemoteMonitor
        if monitor then
            local nameFilter = data.remoteNameFilter or ""
            local limit = math.max(1, math.min(tonumber(data.limit) or 10, 100))
            local hasNameFilter = nameFilter ~= ""

            local results = {}
            local function scanRemotes(parent, depth)
                if #results >= limit * 3 then return end
                if depth > 5 then return end
                for _, child in parent:GetChildren() do
                    if #results >= limit * 3 then break end
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") or child:IsA("UnreliableRemoteEvent") then
                        local name = child.Name
                        if not hasNameFilter or string.find(string.lower(name), string.lower(nameFilter), 1, true) then
                            local fullName = ""
                            pcall(function() fullName = child:GetFullName() end)
                            table.insert(results, {
                                RemoteName = name,
                                RemoteClass = child.ClassName,
                                Direction = "unknown",
                                Method = "basic_mode",
                                TotalCalls = 0,
                                Ignored = false,
                                Blocked = false,
                                RecentCalls = nil,
                                Path = fullName,
                            })
                        end
                    end
                    scanRemotes(child, depth + 1)
                end
            end

            -- Scan common service containers
            local services = {"ReplicatedStorage", "Workspace", "Players"}
            for _, serviceName in services do
                pcall(function()
                    local service = game:GetService(serviceName)
                    scanRemotes(service, 0)
                end)
            end

            -- Trim to limit
            if #results > limit then
                local trimmed = {}
                for i = 1, limit do
                    trimmed[i] = results[i]
                end
                results = trimmed
            end

            monitor.scans += 1
            monitor.lastScanAt = os.time()
            return {
                count = #results,
                results = results,
                mode = "inventory",
                message = "Read-only remote inventory. Call telemetry is unavailable on this executor."
            }
        end
        error("Remote Monitor is not initialised. Call ensure-remote-spy first.")
    end)
end
