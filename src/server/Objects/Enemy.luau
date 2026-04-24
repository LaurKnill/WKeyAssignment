local Enemy = {}
Enemy.__index = Enemy

export type Object = {
    Color: Color3,
    ID: number,
    Size: Vector3,
    Position: Vector3,
    Rotation: number,

    Velocity: Vector3?,
    Destination: Vector3?,
    Target: Model?,
}

function Enemy.new(id: number, color: Color3): Object
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
    local direction = (destination - self.Position).Unit
    self.Velocity = direction * 5
    self.Destination = destination
end

return Enemy