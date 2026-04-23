local Enemy = {}
Enemy.__index = Enemy

export type Object = {
    Color: Color3,
    ID: number,
    Part: Part, -- // PLACEHOLDER UNTIL REPLICATION LOGIC TODO:Replication
}

function Enemy.new(id: number, color: Color3): Object
    local Part = Instance.new("Part")
    Part.Size = Vector3.new(1, 1, 1)
    Part.BrickColor = BrickColor.new(color)
    Part:SetAttribute("ID", id)
    Part.Parent = game.Workspace
    Part.Anchored = true
    Part.Position = Vector3.new(math.random(-24, 24), -5, math.random(-24, 24))

    local self = setmetatable({
        ID = id,
        Color = color,
        Part = Part
    }, Enemy)
    return self
end

return Enemy