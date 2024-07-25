local shaders = {
	---@diagnostic disable-next-line: undefined-field
	force = love.graphics.newComputeShader("shaders/force.glsl"),
	---@diagnostic disable-next-line: undefined-field
	move = love.graphics.newComputeShader("shaders/move.glsl"),
	render = love.graphics.newShader("shaders/render.glsl")
}

local particleCount = 1000
---@diagnostic disable-next-line: undefined-field
local particles = love.graphics.newBuffer({
	{ name = "position", format = "floatvec2" },
	{ name = "velocity", format = "floatvec2" },
	{ name = "kind",     format = "uint32" },
}, particleCount, { shaderstorage = true })

local resolution = {
	x = 1920,
	y = 1080
}

do
	shaders.force:send("Particles", particles)
	shaders.force:send("count", particleCount)
	shaders.force:send("resolution", { resolution.x, resolution.y })

	shaders.move:send("Particles", particles)
	shaders.move:send("count", particleCount)
	shaders.move:send("resolution", { resolution.x, resolution.y })

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

local running = true

function love.update(dt)
	local frictionHalfLife = 0.04
	local frictionFactor = math.pow(0.5, dt / frictionHalfLife)

	shaders.move:send("dt", dt)

	shaders.force:send("dt", dt)
	shaders.force:send("frictionFactor", frictionFactor)

	if (running) then
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
end

function love.draw()
	love.graphics.setShader(shaders.render)

	love.graphics.rectangle("fill", 0, 0, 1920, 1080)
	love.graphics.setShader()
end

function love.keypressed(key)
	if (key == "space") then
		running = not running
	end
end
