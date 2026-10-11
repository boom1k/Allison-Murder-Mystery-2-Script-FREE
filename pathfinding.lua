--[[

	~ Allison | pathfinding ~

	Ground-following A* for teleport paths (Phantom Forces Knife Bot). Every node stands on a
	floor, neighbouring nodes can see each other, and optimizePath cuts the result into steps of
	at most maxStep studs, so the server only ever sees short, unobstructed moves along the ground.

	local pathfinding = loadstring(game:HttpGet(url))()

	local ok, data = pathfinding.floorAStar({
		start = Vector3,
		goal = Vector3,
		parameters = { ... } -- any of DEFAULTS below; unknown keys are ignored
	})
	ok == true  -> data.waypoints = {start, ..., goal}, data.expanded (nodes searched), data.time
	ok == false -> data is the reason: "no path", "timed out", "trial limit" or a usage error

	local path = pathfinding.optimizePath(data.waypoints, 9.9)
	-> the points to move through, start not included, ending at goal. Each point is at most
	   9.9 studs from the one before it (the first one from start). Never empty.

	pathfinding.visualizePath(points, color, lifetime) draws points as dots joined by lines.

]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local pathfinding = {}

local DEFAULTS = {
	step = 3,                 -- grid spacing in studs
	maxtime = 1,              -- seconds before the search gives up (it yields between frames)
	trials = math.huge,       -- nodes searched before it gives up
	mindist = 23,             -- a node this close to the goal that can walk straight to it ends the search
	heuristic = 1.5,          -- 1 = shortest path; higher = faster search, slightly longer path
	maxclimb = 3.5,           -- highest step up between two neighbouring nodes
	maxdrop = 16,             -- deepest step down
	headroom = 2,             -- free space needed above the root
	minnormal = 0.35,         -- floors steeper than ~70 degrees can't be stood on
	framebudget = 0.008,      -- seconds of work per frame before yielding
	respectcancollide = true, -- rays pass through CanCollide = false parts
	hipheight = false,        -- root height above the floor; false = measured under start
	ignore = false,           -- list of instances the rays ignore (characters, effects, ...)
}

local DIRECTIONS = {
	{1, 0}, {-1, 0}, {0, 1}, {0, -1},
	{1, 1}, {1, -1}, {-1, 1}, {-1, -1},
}

local LOOKAHEAD = 8 -- optimizePath tries to skip at most this many points ahead

local lastConfig -- optimizePath reuses the settings of the last search unless given its own

local function makeConfig(start, parameters)
	local config = {}

	for key, value in pairs(DEFAULTS) do
		config[key] = value
	end

	if type(parameters) == "table" then
		for key, value in pairs(parameters) do
			if DEFAULTS[key] ~= nil then
				config[key] = value
			end
		end
	end

	local filter = {}

	if type(config.ignore) == "table" then
		for _, instance in pairs(config.ignore) do
			if typeof(instance) == "Instance" then
				filter[#filter + 1] = instance
			end
		end
	end

	local localPlayer = Players.LocalPlayer
	if localPlayer and localPlayer.Character then
		filter[#filter + 1] = localPlayer.Character
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = filter
	rayParams.IgnoreWater = true
	rayParams.RespectCanCollide = config.respectcancollide and true or false
	config.rayParams = rayParams

	if not config.hipheight then
		local floor = Workspace:Raycast(start, Vector3.new(0, -12, 0), rayParams)
		config.hipheight = floor and math.clamp(start.Y - floor.Position.Y, 1.5, 4.5) or 3
	end

	return config
end

-- binary min-heap on the f cost

local function heapPush(heap, node, priority)
	local items, priorities = heap.items, heap.priorities
	local index = heap.size + 1
	heap.size = index

	while index > 1 do
		local parent = math.floor(index / 2)

		if priorities[parent] <= priority then
			break
		end

		items[index], priorities[index] = items[parent], priorities[parent]
		index = parent
	end

	items[index], priorities[index] = node, priority
end

local function heapPop(heap)
	local items, priorities = heap.items, heap.priorities
	local size = heap.size
	local top = items[1]
	local lastItem, lastPriority = items[size], priorities[size]

	items[size], priorities[size] = nil, nil
	size = size - 1
	heap.size = size

	if size > 0 then
		local index = 1

		while true do
			local child = index * 2

			if child > size then
				break
			end

			if child < size and priorities[child + 1] < priorities[child] then
				child = child + 1
			end

			if lastPriority <= priorities[child] then
				break
			end

			items[index], priorities[index] = items[child], priorities[child]
			index = child
		end

		items[index], priorities[index] = lastItem, lastPriority
	end

	return top
end

-- grid cell + height bucket (2 studs), so floors stacked above each other are different nodes
local function nodeKey(ix, iz, y)
	return (ix + 32768) * 4294967296 + (iz + 32768) * 65536 + (math.floor(y * 0.5 + 0.5) + 32768)
end

-- height of the floor a character could stand on at (x, z), probing down from `top`;
-- false when there is none in reach, it is too steep, or there is no room above it
local function probeFloor(config, x, top, z)
	local depth = config.maxclimb + config.maxdrop + config.hipheight
	local hit = Workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -depth, 0), config.rayParams)

	if not hit or hit.Normal.Y < config.minnormal then
		return false
	end

	local floorY = hit.Position.Y
	local clearance = config.hipheight + config.headroom

	if Workspace:Raycast(Vector3.new(x, floorY + 0.05, z), Vector3.new(0, clearance, 0), config.rayParams) then
		return false
	end

	return floorY
end

-- big height changes go through a corner instead of a diagonal through the ledge:
-- up first then across when climbing, across first then down when dropping
local function cornerBetween(a, b)
	local rise = b.Y - a.Y

	if rise > 1 then
		return Vector3.new(a.X, b.Y, a.Z)
	elseif rise < -1 then
		return Vector3.new(b.X, a.Y, b.Z)
	end
end

local function moveClear(config, a, b, corner)
	local rayParams = config.rayParams

	if corner then
		return not Workspace:Raycast(a, corner - a, rayParams) and not Workspace:Raycast(corner, b - corner, rayParams)
	end

	return not Workspace:Raycast(a, b - a, rayParams)
end

-- a straight move from a to b hits nothing and never gets more than maxclimb above the floor
local function segmentWalkable(config, a, b)
	local offset = b - a
	local length = offset.Magnitude

	if length < 1e-3 then
		return true
	end

	local rayParams = config.rayParams

	if Workspace:Raycast(a, offset, rayParams) then
		return false
	end

	local samples = math.floor(length / config.step)
	local reach = Vector3.new(0, -(config.hipheight + config.maxclimb), 0)

	for sample = 1, samples do
		if not Workspace:Raycast(a + offset * (sample / (samples + 1)), reach, rayParams) then
			return false
		end
	end

	return true
end

local function buildWaypoints(node, goal)
	local reversed = {goal}

	while node do
		reversed[#reversed + 1] = node.position

		if node.corner then
			reversed[#reversed + 1] = node.corner
		end

		node = node.parent
	end

	local waypoints = {}

	for index = #reversed, 1, -1 do
		waypoints[#waypoints + 1] = reversed[index]
	end

	return waypoints
end

function pathfinding.floorAStar(args)
	if type(args) ~= "table" or typeof(args.start) ~= "Vector3" or typeof(args.goal) ~= "Vector3" then
		return false, "floorAStar needs {start = Vector3, goal = Vector3}"
	end

	local start, goal = args.start, args.goal
	local config = makeConfig(start, args.parameters)
	lastConfig = config

	local step = config.step
	local hip = config.hipheight
	local weight = config.heuristic
	local mindist = config.mindist

	local startedAt = os.clock()
	local frameStartedAt = startedAt
	local expanded = 0

	local heap = {items = {}, priorities = {}, size = 0}
	local nodes = {}
	local floors = {}

	local startNode = {position = start, ix = 0, iz = 0, cost = 0}
	nodes[nodeKey(0, 0, start.Y)] = startNode
	heapPush(heap, startNode, (goal - start).Magnitude * weight)

	while heap.size > 0 do
		local node = heapPop(heap)

		if not node.closed then
			node.closed = true
			expanded = expanded + 1

			local position = node.position

			if (goal - position).Magnitude <= mindist and segmentWalkable(config, position, goal) then
				return true, {
					waypoints = buildWaypoints(node, goal),
					expanded = expanded,
					time = os.clock() - startedAt,
				}
			end

			if expanded >= config.trials then
				return false, "trial limit"
			end

			local top = position.Y + config.maxclimb

			for _, direction in ipairs(DIRECTIONS) do
				local ix, iz = node.ix + direction[1], node.iz + direction[2]
				local x, z = start.X + ix * step, start.Z + iz * step

				local probeKey = nodeKey(ix, iz, position.Y)
				local floorY = floors[probeKey]

				if floorY == nil then
					floorY = probeFloor(config, x, top, z)
					floors[probeKey] = floorY
				end

				if floorY then
					local target = Vector3.new(x, floorY + hip, z)
					local rise = target.Y - position.Y

					if rise <= config.maxclimb and -rise <= config.maxdrop then
						local key = nodeKey(ix, iz, target.Y)
						local existing = nodes[key]

						if not (existing and existing.closed) then
							local corner = cornerBetween(position, target)
							local cost = node.cost + (corner and ((corner - position).Magnitude + (target - corner).Magnitude) or (target - position).Magnitude)

							if (not existing or cost < existing.cost) and moveClear(config, position, target, corner) then
								if not existing then
									existing = {ix = ix, iz = iz}
									nodes[key] = existing
								end

								existing.position = target
								existing.corner = corner
								existing.cost = cost
								existing.parent = node

								heapPush(heap, existing, cost + (goal - target).Magnitude * weight)
							end
						end
					end
				end
			end

			local now = os.clock()

			if now - startedAt > config.maxtime then
				return false, "timed out"
			end

			if now - frameStartedAt > config.framebudget and coroutine.isyieldable() then
				task.wait()
				frameStartedAt = os.clock()
			end
		end
	end

	return false, "no path"
end

function pathfinding.optimizePath(waypoints, maxStep, parameters)
	maxStep = tonumber(maxStep) or 9.9

	if type(waypoints) ~= "table" or #waypoints == 0 then
		return {}
	end

	local count = #waypoints
	local config = (parameters and makeConfig(waypoints[1], parameters)) or lastConfig or makeConfig(waypoints[1])

	-- skip every point that a straight, walkable line can go past
	local kept = {waypoints[1]}
	local index = 1
	local frameStartedAt = os.clock()

	while index < count do
		local reach = index + 1

		for candidate = index + 2, math.min(count, index + LOOKAHEAD) do
			if not segmentWalkable(config, waypoints[index], waypoints[candidate]) then
				break
			end

			reach = candidate
		end

		kept[#kept + 1] = waypoints[reach]
		index = reach

		if os.clock() - frameStartedAt > config.framebudget and coroutine.isyieldable() then
			task.wait()
			frameStartedAt = os.clock()
		end
	end

	-- cut every leg into equal steps of at most maxStep
	local path = {}

	for leg = 2, #kept do
		local from, to = kept[leg - 1], kept[leg]
		local pieces = math.max(1, math.ceil((to - from).Magnitude / maxStep))

		for piece = 1, pieces do
			path[#path + 1] = from:Lerp(to, piece / pieces)
		end
	end

	if #path == 0 then
		path[1] = waypoints[count]
	end

	return path
end

function pathfinding.visualizePath(points, color, lifetime)
	local folder = Instance.new("Folder")
	folder.Name = "AllisonPathVisual"
	color = color or Color3.fromRGB(31, 226, 130)

	local function decorate(part)
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Parent = folder
	end

	for index, point in ipairs(points) do
		local dot = Instance.new("Part")
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.new(0.6, 0.6, 0.6)
		dot.Position = point
		decorate(dot)

		local previous = points[index - 1]

		if previous and (point - previous).Magnitude > 1e-3 then
			local line = Instance.new("Part")
			line.Size = Vector3.new(0.12, 0.12, (point - previous).Magnitude)
			line.CFrame = CFrame.lookAt((point + previous) / 2, point)
			decorate(line)
		end
	end

	folder.Parent = Workspace

	if lifetime ~= false then
		Debris:AddItem(folder, lifetime or 5)
	end

	return folder
end

return pathfinding
