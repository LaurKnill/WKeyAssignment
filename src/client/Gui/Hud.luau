local Hud = {}
Hud.State = false
Hud.Classification = "Undefined"

local TweenService = game:GetService("TweenService")
local Player = game:GetService("Players").LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Shared = game.ReplicatedStorage.Shared
local CreateElement = require(Shared.CreateElement)
local ReactiveValue = require(Shared.ReactiveValue)
local Remotes = require(Shared.Remotes)

-- // Gui Values // --

local Gui = Instance.new("ScreenGui")

local EnemiesPerSecondSet = ReactiveValue.new(1, .1)
local MaxEnemiesSet = ReactiveValue.new(20, .1)

local InitSettingFunction = Remotes.getFunction("InitSetting")
local ChangeSettingEvent = Remotes.getEvent("ChangeSetting")
local KillAllEvent = Remotes.getEvent("KillAll")

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

-- // Setup the gui
local function construct()
    Gui.Name = script.Name
    Gui.Parent = PlayerGui

    -- // Spawns per second
    local SpawnsPerSecondFrame, Destroyers = CreateElement("Frame", {
        Name = "SpawnsPerSecond",
        Size = UDim2.fromScale(.3, .13),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        Position = UDim2.fromScale(.065, .15),
        Parent = Gui
    },
    {
        CreateElement("TextLabel", {
            Size = UDim2.fromScale(1, .5),
            BackgroundTransparency = 1,
            TextScaled = true,
            Text = "Spawns Per Second",
        }),
        CreateElement("TextBox", {
            Size = UDim2.fromScale(1, .5),
            BackgroundColor3 = Color3.new(0.631373, 0.964706, 1),
            TextScaled = true,
            Position = UDim2.fromScale(0, 1),
            AnchorPoint = Vector2.new(0, 1),
            Text = EnemiesPerSecondSet,
            FocusLost = function(TextBox: TextBox, Enter_Pressed: boolean, InputObject: InputObject)
                local newSet = tonumber(TextBox.Text)
                if not newSet then
                    TextBox.Text = EnemiesPerSecondSet:Get()
                    return
                end
                newSet = math.clamp(newSet, 0, 1000)
                EnemiesPerSecondSet:Set(newSet)
            end
        })
    })

    -- // Max enemies
    local MaxEnemiesFrame, Destroyers = CreateElement("Frame", {
        Name = "MaxEnemies",
        Size = UDim2.fromScale(.3, .13),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        Position = UDim2.fromScale(.065, .3),
        Parent = Gui
    },
    {
        CreateElement("TextLabel", {
            Size = UDim2.fromScale(1, .5),
            BackgroundTransparency = 1,
            TextScaled = true,
            Text = "Max Enemies",
        }),
        CreateElement("TextBox", {
            Size = UDim2.fromScale(1, .5),
            BackgroundColor3 = Color3.new(0.631373, 0.964706, 1),
            TextScaled = true,
            Position = UDim2.fromScale(0, 1),
            AnchorPoint = Vector2.new(0, 1),
            Text = MaxEnemiesSet,
            FocusLost = function(TextBox: TextBox, Enter_Pressed: boolean, InputObject: InputObject)
                local newSet = tonumber(TextBox.Text)
                if not newSet then
                    TextBox.Text = MaxEnemiesSet:Get()
                    return
                end
                newSet = math.clamp(newSet, 0, 1000)
                MaxEnemiesSet:Set(newSet)
            end
        })
    })

    -- // Kill all
    local KillAllButton, Destroyers = CreateElement("TextButton", {
        Name = "KillAll",
        Size = UDim2.fromScale(.3, .08),
        SizeConstraint = Enum.SizeConstraint.RelativeYY,
        Position = UDim2.fromScale(.065, .45),
        BackgroundColor3 = Color3.new(0.631373, 0.964706, 1),
        Text = "Kill All",
        TextScaled = true,
        Parent = Gui,
        Activated = function()
            KillAllEvent:FireServer()
        end
    })
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

function Hud.toggle(State: boolean?, Instant: boolean?)
    if State ~= nil then
        State = not Hud.State
    end
    if Instant then
        Gui.Enabled = State
    else
        -- // Animation logic would go here
        --    No animation because it isn't being used in this demo, but I'm showing how I usually set up my gui controllers
        Gui.Enabled = State
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function Hud._init()
    print(`[📱] {script.Name}_Gui initialized`)
end

function Hud._start()
    local timeBetweenSpawnsSet, maxEnemiesSet = InitSettingFunction:InvokeServer() or 1, 20
    EnemiesPerSecondSet:SilentSet(1/timeBetweenSpawnsSet)
    MaxEnemiesSet:SilentSet(maxEnemiesSet)
    construct()

    EnemiesPerSecondSet:Subscribe(function(newValue: number)
        ChangeSettingEvent:FireServer("EnemiesPerSecond", newValue)
    end)

    MaxEnemiesSet:Subscribe(function(newValue: number)
        ChangeSettingEvent:FireServer("MaxEnemies", newValue)
    end)

    print(`[📱] {script.Name}_Gui started`)
end

return Hud