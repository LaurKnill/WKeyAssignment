-- // Initializes the physical world

local WorldService = {}

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Local

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Public

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Init

function WorldService._init()
    local BasePlatform = Instance.new("Part")
    BasePlatform.Name = "BasePlatform"
    BasePlatform.Size = Vector3.new(50, 1, 50)
    BasePlatform.Position = Vector3.new(0, -10, 0)
    BasePlatform.Anchored = true
    BasePlatform.CanCollide = true
    BasePlatform.CanTouch = true
    BasePlatform.Parent = workspace
    print("World Service initialized")
end

function WorldService._start()
    print("World service started")
end

return WorldService