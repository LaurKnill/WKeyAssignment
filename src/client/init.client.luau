if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ControllersFolder = script:WaitForChild("Controllers")
local Controllers: {[string]: {any}} = {}

for _, Module in pairs(ControllersFolder:GetChildren()) do
    if Module:IsA("ModuleScript") then
        local Success, ControllerModule = pcall(require, Module)
        if Success and ControllerModule then
            Controllers[Module.Name] = ControllerModule
            if typeof(ControllerModule._init) == "function" then
                ControllerModule._init()
            end
        else
            warn(`[💻] Failed to initialize controller: {Module.Name} with error {tostring(ControllerModule)}`)
        end
    end
end

for name, ModuleController in pairs(Controllers) do
    if typeof(ModuleController._start) == "function" then
        local Success, Result = pcall(function()
            ModuleController._start()
        end)
        if not Success then
            warn(`[💻] Failed to start controller: {name} with error: {tostring(Result)}`)
        end
    end
end