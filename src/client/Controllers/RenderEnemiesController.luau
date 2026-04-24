local RenderEnemiesController = {}

local TweenService = game:GetService("TweenService")

local Root = script.Parent.Parent
local Shared = game.ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local DataTypes = require(Shared.DataTypes)

local GetEnemiesFunction = Remotes.getFunction("GetEnemies")
local EnemySpawnedEvent = Remotes.getEvent("EnemySpawned")
local ClickedOnEvent = Remotes.getEvent("ClickedOn")
local ReplicateEnemiesEvent = Remotes.getEvent("ReplicateEnemies")

local RenderedEnemies: {
    [string]: {
        Part: Part,
        CFrame: CFrame
    }
} = {}

local lastRenderedFrameId = -1

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

local function _clickedOn()
    -- TODO: Clicking on an enemy prints its ID on both server and client
end

local function renderEnemy(EnemyData: DataTypes.NewEnemyRenderData)
    local AlreadyRendered = RenderedEnemies[EnemyData.Id]
    if AlreadyRendered then
        -- This isn't likely to happen, but could if an enemy spawns during client initialization between initial enemy list and receipt of new enemy spawns
        AlreadyRendered.Part.CFrame = CFrame.new(EnemyData.Position) * CFrame.Angles(0, math.rad(EnemyData.Rotation), 0)
        AlreadyRendered.Rotation = EnemyData.Rotation
        AlreadyRendered.Position = EnemyData.Position
        return
    end
    local Part = Instance.new("Part")
    Part.Anchored = true
    Part.CanCollide = true
    Part.CanTouch = true
    Part.Size = EnemyData.Size
    Part.Color = EnemyData.Color
    local CFrame = CFrame.new(EnemyData.Position) * CFrame.Angles(0, math.rad(EnemyData.Rotation), 0)
    Part.CFrame = CFrame
    Part.Parent = workspace
    RenderedEnemies[EnemyData.Id] = {
        Part = Part,
        CFrame = CFrame
    }
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function RenderEnemiesController._init()
    if not GetEnemiesFunction then
        warn("[💻] Render Enemies Controller failed: GetEnemiesFunction not found")
        return
    end
    if not EnemySpawnedEvent then
        warn("[💻] Render Enemies Controller failed: EnemySpawnedEvent not found")
        return
    end
    print("[💻] Render Enemies Controller initialized")
end

function RenderEnemiesController._start()
    lastRenderedFrameId = math.huge -- we're not ready to render anything yet

    ReplicateEnemiesEvent.OnClientEvent:Connect(function(renderFrame: number, EnemyPackage: {[string]: {number}})
        for id, data in pairs(EnemyPackage) do
            if renderFrame < lastRenderedFrameId then
                continue
            end
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

    local InitialEnemies: {[string]: DataTypes.NewEnemyRenderData} = GetEnemiesFunction:InvokeServer() -- In a real project with a larger world, we'd be making this based on chunk
    if InitialEnemies then
        for _, EnemyData in pairs(InitialEnemies) do
            renderEnemy(EnemyData)
        end
    end

    lastRenderedFrameId = -1 -- now we're ready to render enemy updates

    print("[💻] Render Enemies Controller started")
end

return RenderEnemiesController