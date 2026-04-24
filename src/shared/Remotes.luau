-- // Very simple runtime remote event/function creator/locator

local Remotes = {}

local Events: {[string]: RemoteEvent} = {}
local Functions: {[string]: RemoteFunction} = {}

function Remotes.newFunction(name: string): RemoteFunction
    if Functions[name] then
        warn(`[⚠️] RemoteFunction with name {name} already exists!`)
        return Functions[name]
    end
    local newRemote = Instance.new("RemoteFunction")
    newRemote.Name = name
    Functions[name] = newRemote
    newRemote.Parent = script
    return newRemote
end

function Remotes.newEvent(name: string): RemoteEvent
    if Events[name] then
        warn(`[⚠️] RemoteEvent with name {name} already exists!`)
        return Events[name]
    end
    local newRemote = Instance.new("RemoteEvent")
    newRemote.Name = name
    Events[name] = newRemote
    newRemote.Parent = script
    return newRemote
end

function Remotes.newUnreliableRemoteEvent(name: string): RemoteEvent
    if Events[name] then
        warn(`[⚠️] (UnreliableRemoteEvent) RemoteEvent with name {name} already exists!`)
        return Events[name]
    end
    local newRemote = Instance.new("UnreliableRemoteEvent")
    newRemote.Name = name
    newRemote.Parent = script
    Events[name] = newRemote
    return newRemote
end

function Remotes.getFunction(name: string): RemoteFunction?
    return Functions[name]
end

function Remotes.getEvent(name: string): RemoteEvent?
    return Events[name]
end

if game:GetService("RunService"):IsClient() then
    local function register(Remote: Instance)
         if Remote:IsA("RemoteFunction") then
            if Functions[Remote.Name] then
                warn(`[⚠️] RemoteFunction with name {Remote.Name} already exists!`)
                return
            end
            Functions[Remote.Name] = Remote
        elseif Remote:IsA("RemoteEvent") or Remote:IsA("UnreliableRemoteEvent") then
            if Events[Remote.Name] then
                warn(`[⚠️] RemoteEvent with name {Remote.Name} already exists!`)
                return
            end
            Events[Remote.Name] = Remote
        end
    end

    for _, Remote in ipairs(script:GetChildren()) do
        register(Remote)
    end
    script.ChildAdded:Connect(register)
end

return Remotes