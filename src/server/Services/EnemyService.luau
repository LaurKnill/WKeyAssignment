local EnemyService = {}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- // Requires
local WorldService = require(script.Parent.WorldService)

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

local LastPayload: {
    [string]: {number}
} = {}

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

local function destroy(E: Enemy.Object, id: string)
    E:Destroy()
    Enemies[id] = nil
    LastPayload[id] = nil
end

local function runEnemyReplication()
    task.spawn(function()
        if not A_Client_Has_Loaded then
            local elapsed = 0
            repeat
                elapsed += .1
                task.wait(.1)
            until A_Client_Has_Loaded or (elapsed >= 10 and not next(Players:GetPlayers())) -- is this necessary? would there be an issue caused by this thread yielding forever in a completely empty server before shutdown? i dont know. probably not. it's here
        end
        while task.wait(0.15) do
            renderFrame += 1
            local package = {}
            -- // Enemy data is sent including for enemies that haven't moved, which could technically be omitted, but I assume we want this for anti-cheat/consistency
            for id, Enemy in pairs(Enemies) do
                if Enemy.SwagEnabled then
                    continue
                end
                local last = LastPayload[id]
                local x, z, r = Enemy.Position.X, Enemy.Position.Z, Enemy.Rotation
                if not last or last[1] ~= x or last[2] ~= z or last[3] ~= r then
                    local buff = buffer.create(5)
                    buffer.writei16(buff, 0, x * 10) 
                    buffer.writei16(buff, 2, z * 10)
                    buffer.writeu8(buff, 4, (r / 360) * 255) -- Fit rotation into a 0-255
                    package[id] = buff
                    LastPayload[id] = {x, z, r}
                end
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
            if (newPosition - Enemy.Destination).Magnitude < 6 then
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
                        local targetPosition = Target:GetPivot().Position
                        if not WorldService.inBoundsOfEnemyPlatform(targetPosition) then
                            Enemy.Velocity = nil
                            Enemy.Target = nil
                            continue
                        end 
                        local distance = (Enemy.Position - targetPosition).Magnitude
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
                    if not WorldService.inBoundsOfEnemyPlatform(Player.Character.HumanoidRootPart.Position) then
                        continue
                    end
                    local distance = (Enemy.Position - Player.Character:GetPivot().Position).Magnitude
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
    LastPayload[id] = {NewEnemy.Position.X, NewEnemy.Position.Z, NewEnemy.Rotation}
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
    for id, E in pairs(Enemies) do
        destroy(E, id)
        table.insert(Package, id)
    end
    DestroyedEnemiesEvent:FireAllClients(Package)
end

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
                    local E = Enemies[randomId]
                    if not E then
                        warn(`Something went wrong when destroying random enemies!`)
                        break
                    end
                    destroy(E, randomId)
                    table.insert(package, randomId)
                    enemiesToDestroy -= 1
                end
                DestroyedEnemiesEvent:FireAllClients(package)
            end
        end
    end)

    ClickedOnEvent.OnServerEvent:Connect(function(Player: Player, enemyId: string)
        local SpawnedEnemy = Enemies[enemyId]
        if SpawnedEnemy then
            print(enemyId)
        end
    end)

    KillAllEvent.OnServerEvent:Connect(EnemyService.killAll)

    InitSettingFunction.OnServerInvoke = function(Player: Player)
       return timeBetweenEnemySpawns, maxEnemies
    end

    print("[🤖] Enemy service started")
end

return EnemyService