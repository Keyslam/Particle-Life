local ffi = require("ffi")

local shaders = {
	---@diagnostic disable-next-line: undefined-field
	force = love.graphics.newComputeShader("shaders/force.glsl"),
	---@diagnostic disable-next-line: undefined-field
	move = love.graphics.newComputeShader("shaders/move.glsl"),
	---@diagnostic disable-next-line: undefined-field
	count = love.graphics.newComputeShader("shaders/count.glsl"),
	---@diagnostic disable-next-line: undefined-field
	countReduce = love.graphics.newComputeShader("shaders/count_reduce.glsl"),
	---@diagnostic disable-next-line: undefined-field
	gather = love.graphics.newComputeShader("shaders/gather.glsl"),

	render = love.graphics.newShader("shaders/render.glsl")
}

local resolution = {
	x = 1920,
	y = 1080
}

local particleCount = 800
local cellSize = 120
local gridWidth = math.ceil(resolution.x / cellSize)

local counters = 40
local segmentSize = particleCount / counters

---@diagnostic disable-next-line: undefined-field
local particles = love.graphics.newBuffer({
	{ name = "position", format = "floatvec2" },
	{ name = "velocity", format = "floatvec2" },
	{ name = "kind",     format = "uint32" },
}, particleCount, { shaderstorage = true })

---@diagnostic disable-next-line: undefined-field
local particleCells = love.graphics.newBuffer({
	{ name = "particleId", format = "uint32" },
	{ name = "cellId",     format = "uint32" },
}, particleCount, { shaderstorage = true })

---@diagnostic disable-next-line: undefined-field
local counts = love.graphics.newBuffer({
	{ name = "value", format = "uint32" },
}, counters * segmentSize * 16, { shaderstorage = true })

local countsReduce = love.graphics.newBuffer({
	{ name = "value", format = "uint32" },
}, 16, { shaderstorage = true })

local prefixSum = love.graphics.newBuffer({
	{ name = "value", format = "uint32" },
}, 16, { shaderstorage = true })

local offsets = love.graphics.newBuffer({
	{ name = "value", format = "uint32" },
}, 16 * 40, { shaderstorage = true })

---@diagnostic disable-next-line: undefined-field
local particleCellsOut = love.graphics.newBuffer({
	{ name = "particleId", format = "uint32" },
	{ name = "cellId",     format = "uint32" },
}, particleCount, { shaderstorage = true })

do
	shaders.force:send("Particles", particles)
	shaders.force:send("count", particleCount)
	shaders.force:send("resolution", { resolution.x, resolution.y })

	shaders.move:send("Particles", particles)
	shaders.move:send("ParticleCells", particleCells)
	shaders.move:send("count", particleCount)
	shaders.move:send("resolution", { resolution.x, resolution.y })
	shaders.move:send("cellSize", cellSize)
	shaders.move:send("gridWidth", gridWidth)
	
	shaders.count:send("count", particleCount)
	shaders.count:send("segmentSize", segmentSize)
	shaders.count:send("Counts", counts)
	shaders.count:send("ParticleCells", particleCells)
	
	shaders.countReduce:send("segments", counters)
	shaders.countReduce:send("Counts", counts)
	shaders.countReduce:send("CountReduce", countsReduce)
	shaders.countReduce:send("PrefixSum", prefixSum)
	shaders.countReduce:send("Offsets", offsets)
	
	shaders.gather:send("count", particleCount)
	shaders.gather:send("segmentSize", segmentSize)
	shaders.gather:send("ParticleCells", particleCells)
	shaders.gather:send("ParticleCellsOut", particleCellsOut)
	shaders.gather:send("Offsets", offsets)
	
	shaders.render:send("Particles", particles)
	shaders.render:send("count", particleCount)
end

do
	local data = {}
	local r, rn = love.math.random, love.math.randomNormal
	for i = 1, particleCount do
		table.insert(data, {
			r(resolution.x), r(resolution.y),
			rn(0), rn(0),
			r(7)
		})
	end

	particles:setArrayData(data)
end

do
	local attractionmatrix = {}
	for i = 1, 7 * 7 do
		attractionmatrix[i] = love.math.random() * 2 - 1;
	end
	shaders.force:send("attractionmatrix", unpack(attractionmatrix))
end

do
	ffi.cdef([[
		typedef struct particleCell {
			uint32_t particleId;
			uint32_t cellId;
		} particleCell;
	]])

	ffi.cdef([[
		typedef struct particle {
			float position_x;
			float position_y;
			float velocity_x;
			float velocity_y;
			uint32_t kind;
			bool _;
		} particle;
	]])

	ffi.cdef([[
		typedef struct count {
			uint32_t value;
		} count;
	]])
end

local function step(dt)
	local frictionHalfLife = 0.04
	local frictionFactor = math.pow(0.5, dt / frictionHalfLife)

	shaders.move:send("dt", dt)

	shaders.force:send("dt", dt)
	shaders.force:send("frictionFactor", frictionFactor)

	do
		local groupCount = math.ceil(particleCount / shaders.force:getLocalThreadgroupSize())
		---@diagnostic disable-next-line: undefined-field
		love.graphics.dispatchThreadgroups(shaders.force, groupCount)
	end

	do
		local groupCount = math.ceil(particleCount / shaders.move:getLocalThreadgroupSize())
		---@diagnostic disable-next-line: undefined-field
		love.graphics.dispatchThreadgroups(shaders.move, groupCount)
	end
end

function love.draw()
	love.graphics.setShader(shaders.render)
	love.graphics.rectangle("fill", 0, 0, 1920, 1080)
	love.graphics.setShader()

	step(0.01)

	local particleCells = ffi.cast("particleCell*", love.graphics.readbackBuffer(particleCells):getFFIPointer())
	local particles = ffi.cast("particle*", love.graphics.readbackBuffer(particles):getFFIPointer())

	love.graphics.setColor(1, 1, 1, 0.3)
	for x = 0, gridWidth - 1 do
		for y = 0, math.ceil(resolution.y / cellSize) - 1 do
			love.graphics.rectangle("line", x * cellSize, y * cellSize, cellSize, cellSize)

			local id = x + (y * gridWidth)
			love.graphics.printf(tostring(id), x * cellSize, y * cellSize, cellSize, "center")
		end
	end

	love.graphics.setColor(1, 1, 1, 0.3)
	for i = 0, particleCount - 1 do
		local particle = particles[i]
		love.graphics.circle("line", particle.position_x, particle.position_y, 8)
	end

	love.graphics.setColor(1, 1, 1, 0.8)
	for i = 0, particleCount - 1 do
		local particle = particles[i]
		local particleCell = particleCells[i]
		love.graphics.print(particleCell.cellId, particle.position_x, particle.position_y)
	end

	love.graphics.dispatchThreadgroups(shaders.count, 1)
	love.graphics.dispatchThreadgroups(shaders.countReduce, 1)
	love.graphics.dispatchThreadgroups(shaders.gather, 1)
	
	local countsReduce = ffi.cast("count*", love.graphics.readbackBuffer(countsReduce):getFFIPointer())
	print("--- Count ---")
	for i = 0, 15 do
		print(i, countsReduce[i].value)
	end

	print("--- Prefix Sum ---")
	local prefixSum = ffi.cast("count*", love.graphics.readbackBuffer(prefixSum):getFFIPointer())
	for i = 0, 15 do
		print(i, prefixSum[i].value)
	end

	local offsets = ffi.cast("count*", love.graphics.readbackBuffer(offsets):getFFIPointer())
	print("--- Offsets ---")
	for j = 0, 15 do
		for i = 0, 39 do
			local offset = offsets[i * 16 + j]
			print(i, j, offset.value)
		end
	end
	
	print("--- Sorted particle cells ---")
	local particleCellsOut = ffi.cast("particleCell*", love.graphics.readbackBuffer(particleCellsOut):getFFIPointer())
	for i = 0, particleCount - 1 do
		local particleCell = particleCellsOut[i]
		print(i, string.format("%x", particleCell.cellId), particleCell.particleId)
	end
end


