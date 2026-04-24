local EnemyService = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- // Requires
local Root = script.Parent.Parent
local Objects = Root.Objects
local Enemy = require(Objects.Enemy)
local Enemies = require(Root.Modules.Enemies)

local Shared = game.ReplicatedStorage.Shared
local Remotes = require(Shared.Remotes)
local DataTypes = require(Shared.DataTypes)

-- // Configurable
local timeBetweenEnemySpawns = 1
local enemiesCreated = 0
local maxEnemies = 20

-- // Other
local sinceLastSpawn = 0 -- deltatime elapsed since the last enemey spawn
local renderFrame = 0
local minimumChaseDistance = 15
local A_Client_Has_Loaded = false -- May not be the most necessary in a live game but it prevents annoying edge cases during development where enemies are behaving before the client has registered local remotes

-- // Events
local EnemySpawnedEvent = Remotes.newEvent("EnemySpawned")
local GetEnemiesFunction = Remotes.newFunction("GetEnemies")
local ClickedOnEvent = Remotes.newEvent("ClickedOn")
local EnemyBecameSwagEvent = Remotes.newEvent("EnemyBecameSwag")
local DestroyedEnemiesEvent = Remotes.newEvent("DestroyedEnemies")
local ReplicateEnemiesEvent = Remotes.newUnreliableRemoteEvent("ReplicateEnemies")
local ChangeSettingEvent = Remotes.newEvent("ChangeSetting")
local KillAllEvent = Remotes.newEvent("KillAll")
local InitSettingFunction = Remotes.newFunction("InitSetting")

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

local function runEnemyReplication()
    task.spawn(function()
        if not A_Client_Has_Loaded then
            local elapsed = 0
            repeat
                elapsed += .1
                task.wait(.1)
            until A_Client_Has_Loaded or (elapsed >= 10 and not next(Players:GetPlayers())) -- is this necessary? would there be an issue caused by this thread yielding forever in a completely empty server before shutdown? i dont know. probably not. it's here
        end
        while task.wait(0.1) do
            renderFrame += 1
            local package = {}
            -- // Enemy data is sent including for enemies that haven't moved, which could technically be omitted, but I assume we want this for anti-cheat/consistency
            -- TODO: payload begins exceeding at high levels of NPCs!!
            for id, Enemy in pairs(Enemies) do
                if Enemy.SwagEnabled then
                    continue
                end
                package[id] = {Enemy.Position.X, Enemy.Position.Z, Enemy.Rotation}
            end
            ReplicateEnemiesEvent:FireAllClients(renderFrame, package)
        end
    end)
end

local function runEnemyVelocity()
    RunService.Heartbeat:Connect(function(dt)
        -- Check enemy spawns
        -- If enough time has passed (using dt) since the last enemy spawn, create a new enemy
        if Enemy.LivingEnemies < maxEnemies then
            sinceLastSpawn += dt
            if sinceLastSpawn >= timeBetweenEnemySpawns then
                sinceLastSpawn -= timeBetweenEnemySpawns
                EnemyService.spawnEnemy()
            end
        end

        -- Move enemies
        for id, Enemy in pairs(Enemies) do
            if Enemy.SwagEnabled then
                continue -- Enemy has already touched player
            end
            local Velocity = Enemy.Velocity
            local Target = Enemy.Target
            if not Velocity or not Target then
                continue
            end
            if not Target.Parent then -- Target player has despawned
                Enemy.Velocity = nil
                Enemy.Target = nil
                continue
            end
            Enemy:MoveToTarget(Target)
            local newPosition = Enemy.Position + (Velocity * dt)
            Enemy.Position = newPosition
            if (newPosition - Enemy.Destination).Magnitude < 1 then
                Enemy.Velocity = nil
                Enemy.Target = nil
                Enemy:BecomeSwag()
                EnemyBecameSwagEvent:FireAllClients(id)
            end
        end
    end)
end

local function runEnemyBehavior()
    task.spawn(function()
        while task.wait(.25) do
            for id, Enemy in pairs(Enemies) do
                -- // Assess movement of already moving enemies
                if Enemy.Velocity then
                    local Target = Enemy.Target
                    if Target then
                        if not Target.Parent then
                            Enemy.Velocity = nil
                            Enemy.Target = nil
                            continue
                        end
                        local distance = (Enemy.Position - Target.HumanoidRootPart.Position).Magnitude
                        if distance > minimumChaseDistance then
                            Enemy.Velocity = nil
                            Enemy.Target = nil
                            continue
                        end
                    end
                    continue
                end
                -- // Assess chase initiation of non moving enemies
                local TargetPlayer = nil
                for _, Player in pairs(Players:GetPlayers()) do
                    if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
                        continue
                    end
                    local distance = (Enemy.Position - Player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < minimumChaseDistance then
                        TargetPlayer = Player
                        break
                    end
                end
                if TargetPlayer then
                    Enemy.Target = TargetPlayer.Character
                    Enemy:MoveToTarget(TargetPlayer.Character)
                end
            end
        end
    end)
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

function EnemyService.spawnEnemy()
    enemiesCreated += 1
    local id = tostring(enemiesCreated)
    local NewEnemy = Enemy.new(id, BrickColor.Random().Color)
    Enemies[id] = NewEnemy
    EnemySpawnedEvent:FireAllClients({
                Id = id,
                Color = NewEnemy.Color,
                Size = NewEnemy.Size,
                Swag = NewEnemy.SwagEnabled,
                Position = NewEnemy.Position,
                Rotation = NewEnemy.Rotation
        }
    )
end

function EnemyService.killAll()
    local Package = {}
    for id, Enemy in pairs(Enemies) do
        Enemy:Destroy()
        Enemies[id] = nil
        table.insert(Package, id)
    end
    DestroyedEnemiesEvent:FireAllClients(Package)
end

--[[
ENEMY BEHAVIOR:
    [ ] TODO: IGNORES PLAYERS OUTSIDE OF THE PLATFORM!
    [x] When an enemy is close to a player, they do something. They can play an animation, attack and deal damage, or just print to console
    [ ] (Optional) enemy wanders within their platform randomly
]]

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function EnemyService._init()
    runEnemyBehavior()
    runEnemyVelocity()
    runEnemyReplication()
    print("[🤖] Enemy service initialized")
end

function EnemyService._start()
    GetEnemiesFunction.OnServerInvoke = function(Player: Player)
        A_Client_Has_Loaded = true
        local EnemyData: {[string]: DataTypes.NewEnemyRenderData} = {}
        for id, Enemy in pairs(Enemies) do
            EnemyData[id] = {
                Id = id,
                Color = Enemy.Color,
                Size = Enemy.Size,
                Swag = Enemy.SwagEnabled,
                Position = Enemy.Position,
                Rotation = Enemy.Rotation
            }
        end
        return EnemyData
    end

    ChangeSettingEvent.OnServerEvent:Connect(function(Player: Player, settingName: "EnemiesPerSecond" | "MaxEnemies", newValue: number)
        if settingName == "EnemiesPerSecond" then
            timeBetweenEnemySpawns = 1 / newValue
        elseif settingName == "MaxEnemies" then
            maxEnemies = newValue
            if maxEnemies < Enemy.LivingEnemies then
                local package = {}
                local enemiesToDestroy = Enemy.LivingEnemies - maxEnemies
                local idsList = {}
                for id, _ in pairs(Enemies) do
                    table.insert(idsList, id)
                end
                local i = #idsList
                while enemiesToDestroy > 0 and i > 0 do
                    i -= 1
                    local randomIndex = math.random(#idsList)
                    local randomId = idsList[randomIndex]
                    table.remove(idsList, randomIndex)
                    local Enemy = Enemies[randomId]
                    if not Enemy then
                        warn(`Something went wrong when destroying random enemies!`)
                        break
                    end
                    Enemy:Destroy()
                    Enemies[randomId] = nil
                    table.insert(package, randomId)
                    enemiesToDestroy -= 1
                end
                DestroyedEnemiesEvent:FireAllClients(package)
            end
        end
    end)

    ClickedOnEvent.OnServerEvent:Connect(function(Player: Player, enemyId: string)
        print(`Clicked on {enemyId}`) -- TODO: implement
    end)

    KillAllEvent.OnServerEvent:Connect(EnemyService.killAll)

    InitSettingFunction.OnServerInvoke = function(Player: Player)
       return timeBetweenEnemySpawns, maxEnemies
    end

    print("[🤖] Enemy service started")
end

return EnemyService