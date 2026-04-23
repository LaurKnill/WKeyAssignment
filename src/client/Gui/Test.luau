local GuiTemplate = {}
GuiTemplate.State = false
GuiTemplate.Classification = "Undefined"

local TweenService = game:GetService("TweenService")
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- // Gui Values // --

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

function GuiTemplate.toggle(State: boolean?, Instant: boolean?)
    if State ~= nil then
        State = not GuiTemplate.State
    end
    -- > Open/Close gui
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function GuiTemplate._init()
    print(`{script.Name} gui controller initialized`)
end

function GuiTemplate._start()
    print(`{script.Name} gui controller started`)
end

return GuiTemplate