local EnemyService = {}

-- // Requires
local Objects = script.Parent.Parent.Objects
local Enemy = require(Objects.Enemy)

--[[
1 enemy spawn per second
20 enemies maximum (enemies stop spawning when cap is reached) 
The above variables can be adjusted through a user-interface of any kind (billboard, physical buttons, ui, etc)
> REMOTES
> CONFIGURATIONS: spawns per second, max enemies
]]

local enemiesCreated = 0

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

function EnemyService.spawnEnemy()
    --[[
        [x] 50x50 platform exists
            [ ] Spawn enemies on it (wait for replication logic)
        [x] Enemies have random attributes (color, material, size)
        [x] Enemies have unique IDs
            [ ] Replicated to client (wait for replication logic)
            [ ] Clicking an enemy prints its ID on both server and client
    ]]
    enemiesCreated += 1
    local id = enemiesCreated
    local NewEnemy = Enemy.new(id, BrickColor.Random().Color)
    --> REPLICATE TO CLIENT Todo:Replication
end

function EnemyService.killAll()
    -- Client UI button to kill all
end

--[[
CUSTOM REPLICATION
    Enemy movement should be as performant as possible in regard to replication cost
    Submissions will be judged based on the network ‘Recv’ stat in ‘performance stats’
]]

--[[
ENEMY BEHAVIOR:
    Enemy chases the closest player who is on their platform. Ignores players outside of the platform
    When an enemy is close to a player, they do something. They can play an animation, attack and deal damage, or just print to console
    Enemies are not required to pathfind
    (Optional) enemy wanders within their platform randomly
]]

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function EnemyService._init()
    for i = 1, 20 do -- TODO: adjustable 1 spawn per second until 20 max
        EnemyService.spawnEnemy()
    end
    print("[🤖] Enemy service initialized")
end

function EnemyService._start()
    print("[🤖] Enemy service started")
end

return EnemyService