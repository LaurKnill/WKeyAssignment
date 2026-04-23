local GuiController = {}

local GuiControllersFolder = script.Parent.Parent:WaitForChild("Gui")

export type GuiClassification = "Undefined" | "In Game Hover" -- Or others

export type GuiController = {
    State: boolean,
    Classification:  GuiClassification,

    toggle: ((State: boolean?, Instant: boolean?) -> ())?,
}

local GuiControllers: {[string]: GuiController} = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

-- // Note: A lot of these aren't used because this is a simple af assignment but I am showing an example of what I am used to gui controllers functioning like

function GuiController.get(guiName: string): GuiController?
    return GuiControllers[guiName]
end

-- // Toggle any gui on/off
function GuiController.toggle(guiName: string, State: boolean?, Instant: boolean?)
    local Controller = GuiControllers[guiName]
    if not Controller then
        warn(`No GUI controller found with name: {guiName}`)
        return
    end
    if not Controller.toggle then
        warn(`GUI controller does not have a toggle function: {guiName}`)
        return
    end
    if State == nil then
        State = not Controller.State
    end
    Controller.toggle(State, Instant)
end

-- // Disable all gui of a class
function GuiController.disableClass(Classification: GuiClassification, Instant: boolean?)
    for _, Controller in pairs(GuiControllers) do
        if Controller.Classification == Classification and Controller.State and Controller.toggle then
            Controller.toggle(false, Instant)
        end
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function GuiController._init()
    for _, GuiModule in pairs(GuiControllersFolder:GetChildren()) do
        if GuiModule:IsA("ModuleScript") then
            local Success, Controller = pcall(require, GuiModule)
            if Success and Controller and type(Controller) == "table" then
                GuiControllers[GuiModule.Name] = Controller
                Controller._init()
            else
                warn(`Failed to initialize gui controller: {GuiModule.Name}`)
            end
        end
    end

    print("[💻] Gui Controller initialized")
end

function GuiController._start()
    for _, Controller in pairs(GuiControllers) do
        local Success, Error = pcall(Controller._start)
        if not Success then
            warn(`Failed to start gui controller: {Error}`)
        end 
    end
    print("[💻] Gui Controller started")
end

return GuiController