local Enemy = {}
Enemy.__index = Enemy

Enemy.LivingEnemies = 0

local Shared = game.ReplicatedStorage.Shared
local Config = require(Shared.Config)

export type Object = {
    Color: Color3,
    ID: number,
    Size: Vector3,
    Position: Vector3,
    Rotation: number,
    
    SwagEnabled: boolean?,

    Velocity: Vector3?,
    Destination: Vector3?,
    Target: Model?,

    MoveToTarget: (self: Object, Target: Model)->(),
    Destroy: (self: Object)->()
}

function Enemy.new(id: number, color: Color3): Object
    Enemy.LivingEnemies += 1
    local self = setmetatable({
        ID = id,
        Color = color,
        Size = Vector3.new(1, 3, 1),
        Position = Vector3.new(math.random(-24, 24), -5, math.random(-24, 24)),
        Rotation = math.random(0, 360)
    }, Enemy)
    return self
end

function Enemy:MoveToTarget(Target: Model)
    local destination = Target:GetPivot().Position
    destination = Vector3.new(destination.X, Config.EnemyHeight, destination.Z)
    local direction = (destination - self.Position).Unit
    local radians = math.atan2(direction.X, direction.Z)
    self.Velocity = direction * 5
    self.Destination = destination
    self.Rotation = math.deg(radians) % 360
end

function Enemy:BecomeSwag()
    self.SwagEnabled = true
end

-- // Remember to remove references elsewhere!
function Enemy:Destroy()
    Enemy.LivingEnemies -= 1
    table.clear(self)
end

return Enemy