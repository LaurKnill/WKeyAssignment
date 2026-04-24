local RenderEnemiesController = {}

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent
local Shared = game.ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local DataTypes = require(Shared.DataTypes)
local Config = require(Shared.Config)

local GetEnemiesFunction = Remotes.getFunction("GetEnemies")
local EnemySpawnedEvent = Remotes.getEvent("EnemySpawned")
local ClickedOnEvent = Remotes.getEvent("ClickedOn")
local ReplicateEnemiesEvent = Remotes.getEvent("ReplicateEnemies")
local EnemyBecameSwagEvent = Remotes.getEvent("EnemyBecameSwag")

local RenderedEnemies: {
    [string]: {
        Part: Part,
        CFrame: CFrame,
        Swag: true?
    }
} = {}

local lastRenderedFrameId = -1

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

local function _clickedOn()
    -- TODO: Clicking on an enemy prints its ID on both server and client
end

local function swagify(enemyId: string)
    local RenderedEnemy = RenderedEnemies[enemyId]
    if RenderedEnemy then
        local Part = RenderedEnemy.Part
        Part.Size = Vector3.new(4, 7.5, .01)
        Part.Transparency = 1

        -- These aren't stored anywhere because in this demo nothing further is done with them
        local FrontDecal = Instance.new("Decal")
        FrontDecal.Parent = Part
        FrontDecal.Face = Enum.NormalId.Front
        FrontDecal.Texture = "http://www.roblox.com/asset/?id=73257033"
        local BackDecal = FrontDecal:Clone()
        BackDecal.Face = Enum.NormalId.Back
        BackDecal.Parent = Part
        RenderedEnemy.Swag = true
    end
end

-- // Swags face the client at all times
local function renderSwags()
    RunService.Heartbeat:Connect(function()
        for id, RenderedEnemy in pairs(RenderedEnemies) do
            if not RenderedEnemy.Swag then
                continue
            end
            -- Rotate RenderedEnemy.Part to face the client character
            local Character = game.Players.LocalPlayer.Character
            if not Character or not Character:FindFirstChild("HumanoidRootPart") then
                continue
            end
            local MyPosition = Character:GetPivot().Position
            local myPositionFlat = Vector3.new(MyPosition.X, RenderedEnemy.Part.Position.Y, MyPosition.Z)
            RenderedEnemy.Part.CFrame = CFrame.lookAt(RenderedEnemy.Part.Position, myPositionFlat)
        end
    end)
end

local function renderEnemy(EnemyData: DataTypes.NewEnemyRenderData)
    local AlreadyRendered = RenderedEnemies[EnemyData.Id]
    if AlreadyRendered then
        -- This isn't likely to happen, but could if an enemy spawns during client initialization between initial enemy list and receipt of new enemy spawns
        AlreadyRendered.Part.CFrame = CFrame.new(EnemyData.Position) * CFrame.Angles(0, math.rad(EnemyData.Rotation), 0)
        AlreadyRendered.Rotation = EnemyData.Rotation
        AlreadyRendered.Position = EnemyData.Position
        if AlreadyRendered.Swag then
            swagify(EnemyData.Id)
        end
        return
    end
    local Part = Instance.new("Part")
    Part.Anchored = true
    Part.CanCollide = false
    Part.Size = EnemyData.Size
    Part.Color = EnemyData.Color
    local CFrame = CFrame.new(EnemyData.Position) * CFrame.Angles(0, math.rad(EnemyData.Rotation), 0)
    Part.CFrame = CFrame
    Part.Parent = workspace
    RenderedEnemies[EnemyData.Id] = {
        Part = Part,
        CFrame = CFrame
    }
    if EnemyData.Swag then
        swagify(EnemyData.Id)
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function RenderEnemiesController._init()
    if not GetEnemiesFunction or not EnemySpawnedEvent or not ReplicateEnemiesEvent or not EnemyBecameSwagEvent or not ClickedOnEvent then
        warn("[💻] Render Enemies Controller failed: One or more required events not found")
        return
    end
    print("[💻] Render Enemies Controller initialized")
end

function RenderEnemiesController._start()
    lastRenderedFrameId = math.huge -- we're not ready to render anything yet

    ReplicateEnemiesEvent.OnClientEvent:Connect(function(renderFrame: number, EnemyPackage: {[string]: {number}})
        if lastRenderedFrameId == -1 then
            -- This is the first frame; instantly place all enemies as they may have already moved greatly from their original loaded positions
            -- (in a more professional project we could probably set up a separate initial event, disconnect that, and then setup a normal event, but that's trying too hard here)
            lastRenderedFrameId = renderFrame
            for id, data in pairs(EnemyPackage) do
                local RenderedEnemy = RenderedEnemies[id]
                if not RenderedEnemy then
                    print(`~ Skipping enemy not yet rendered`)
                    continue
                end
                local positionX = data[1]
                local positionZ = data[2]
                local rotation = data[3]
                local newCFrame = CFrame.new(positionX, Config.EnemyHeight, positionZ) * CFrame.Angles(0, math.rad(rotation), 0)
                RenderedEnemy.CFrame = newCFrame
                RenderedEnemy.Part.CFrame = newCFrame
            end
            return
        end
        if renderFrame < lastRenderedFrameId then
            return
        end
        for id, data in pairs(EnemyPackage) do
            lastRenderedFrameId = renderFrame
            local RenderedEnemy = RenderedEnemies[id]
            if not RenderedEnemy then
                print(`~ Skipping enemy not yet rendered`)
                continue
            end
            local positionX = data[1]
            local positionZ = data[2]
            local rotation = data[3]
            local newCFrame = CFrame.new(positionX, -5, positionZ) * CFrame.Angles(0, math.rad(rotation), 0)
            RenderedEnemy.CFrame = newCFrame
            TweenService:Create(RenderedEnemy.Part, TweenInfo.new(0.25, Enum.EasingStyle.Linear), {CFrame = newCFrame}):Play()
        end
    end)

    EnemySpawnedEvent.OnClientEvent:Connect(function(EnemyData: DataTypes.NewEnemyRenderData)
        renderEnemy(EnemyData)
    end)

    -- // TODO: Moves weirdly for a second, i think because the last position tween is still in motion
    EnemyBecameSwagEvent.OnClientEvent:Connect(swagify)

    local InitialEnemies: {[string]: DataTypes.NewEnemyRenderData} = GetEnemiesFunction:InvokeServer() -- In a real project with a larger world, we'd be making this based on chunk
    if InitialEnemies then
        for _, EnemyData in pairs(InitialEnemies) do
            renderEnemy(EnemyData)
        end
    end

    lastRenderedFrameId = -1 -- now we're ready to render enemy updates
    renderSwags()

    print("[💻] Render Enemies Controller started")
end

return RenderEnemiesController