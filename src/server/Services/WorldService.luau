-- // Initializes the physical world

local WorldService = {}

local enemyPlatformPosition = Vector3.new(0, -10, 0)
local enemyPlatformWidth = 50

local boundsX = enemyPlatformPosition.X + (enemyPlatformWidth/2)
local boundsY = enemyPlatformPosition.Y + 5
local boundsZ = enemyPlatformPosition.Z + (enemyPlatformWidth/2)

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

function WorldService.inBoundsOfEnemyPlatform(position: Vector3): boolean
    local x, y, z = position.X, position.Y, position.Z
    if y < boundsY and y > enemyPlatformPosition.Y and x < boundsX and x > -boundsX and z < boundsZ and z > -boundsZ then
        return true
    else
        return false
    end
end

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function WorldService._init()
    local EnemyPlatform = Instance.new("Part")
    EnemyPlatform.Name = "EnemyPlatform"
    EnemyPlatform.Size = Vector3.new(enemyPlatformWidth, 1, enemyPlatformWidth)
    EnemyPlatform.Position = enemyPlatformPosition
    EnemyPlatform.Anchored = true
    EnemyPlatform.CanCollide = true
    EnemyPlatform.CanTouch = true
    EnemyPlatform.Parent = workspace

    local LargerPlatform = Instance.new("Part")
    LargerPlatform.Name = "LargerPlatform"
    LargerPlatform.Size = Vector3.new(100, 1, 100)
    LargerPlatform.Position = Vector3.new(0, -15, 0)
    LargerPlatform.Anchored = true
    LargerPlatform.CanCollide = true
    LargerPlatform.CanTouch = true
    LargerPlatform.Parent = workspace
    print("[🤖] World Service initialized")
end

function WorldService._start()
    print("[🤖] World service started")
end

return WorldService