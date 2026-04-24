-- // Holds list of active spawned enemies

local Root = script.Parent.Parent
local Enemy = require(Root.Objects.Enemy)

local Enemies: { [string]: Enemy.Object} = {}

return Enemies