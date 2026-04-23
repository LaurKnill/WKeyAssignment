local Services: {[string]: ModuleScript} = {}

-- // Init
for i, Service in pairs(script.Services:GetChildren()) do
    if Service:IsA("ModuleScript") then
        local Success, Result = pcall(function()
            local ServiceModule = require(Service)
            if type(ServiceModule._init) == "function" then
                ServiceModule._init()
            end
        end)
        if not Success then
            warn(`Failed to initialize service: {Service.Name} with error: {tostring(Result)}`)
        end
    end
end

-- // Start
for name, ServiceModule in pairs(Services) do
    if type(ServiceModule._start) == "function" then
        local Success, Result = pcall(function()
            ServiceModule._start()
        end)
        if not Success then
            warn(`Failed to start service: {name} with error: {tostring(Result)}`)
        end
    end
end