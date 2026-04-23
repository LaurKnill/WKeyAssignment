-- Initialize
for i, Service in pairs(script.Services:GetChildren()) do
    if Service:IsA("ModuleScript") then
        local Success, Result = pcall(function()
            local ServiceModule = require(Service)
            if type(ServiceModule._init) == "function" then
                ServiceModule._init()
            end
        end)
        if not Success then
            warn("Failed to initialize service: " .. Service.Name .. " with error: " .. tostring(Result))
        end
    end
end

for i, Service in pairs(script.Services:GetChildren()) do
    if Service:IsA("ModuleScript") then
        local Success, Result = pcall(function()
            local ServiceModule = require(Service)
            if type(ServiceModule._start) == "function" then
                ServiceModule._start()
            end
        end)
        if not Success then
            warn("Failed to start service: " .. Service.Name .. " with error: " .. tostring(Result))
        end
    end
end