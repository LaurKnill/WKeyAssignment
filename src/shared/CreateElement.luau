-- // This is a simple replacement for common features in ui utilities, like React
--    I've looked around at figuring out which one to install for this demo, but ultimately I just need to simply create little UI elements for this project, so I went a simple route

return function(ClassName, Properties, Children): (Instance, {()->()})
    local Element = Instance.new(ClassName)
    local Connections: {[string]: RBXScriptConnection | ()->()} = {}
    local Destroyers = {}

    if Properties then
        for Property, Value in pairs(Properties) do
            local prop = Element[Property]
            if typeof(prop) == "RBXScriptSignal" then
                -- // Connect a signal value
                Connections[prop] = prop:Connect(function(...)
                    Value(Element, ...)
                end)
            elseif typeof(Value) == "table" and Value._isReactive then
                -- // Connect a reactive value
                Element[Property] = Value:Get()
                local connection = Value:Subscribe(function(newValue)
                    if Element.Parent then 
                        Element[Property] = newValue
                    else
                        warn(`Cleanup setup error: Called a reactive value on an element that no longer exists! {Element.Name}`)
                    end
                end)
                Connections[prop] = connection
            else
                -- // Set a normal property
                Element[Property] = Value
            end
        end
    end

    -- // Assign children
    if Children then
        for _, Child in pairs(Children) do
            if typeof(Child) == "Instance" then
                Child.Parent = Element
            elseif typeof(Child) == "function" then
                table.insert(Destroyers, Child) -- Destroyer function from child elements
            end
        end
    end

    table.insert(Destroyers, function()
        for key, Connection in pairs(Connections) do
            if Connection:IsA("RbxScriptConnection") then
                Connection:Disconnect() -- Connection
            elseif typeof(Connection) == "function" then
                Connection() -- Reactive Value cleaner function
            end
        end
        table.clear(Connections)
        Element:Destroy()
    end)

    return Element, Destroyers
end