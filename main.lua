local colors = {
    { love.math.colorFromBytes(234, 89, 89) },
    { love.math.colorFromBytes(234, 168, 86) },
    { love.math.colorFromBytes(239, 215, 127) },
    { love.math.colorFromBytes(143, 217, 86) },
    { love.math.colorFromBytes(99, 216, 162) },
    { love.math.colorFromBytes(73, 142, 188) },
    { love.math.colorFromBytes(106, 85, 209) },
}

local function createAttractionMatrix()
    local attractionMatrix = {}

    for i = 1, #colors do
        attractionMatrix[i] = {}
        for j = 1, #colors do
            attractionMatrix[i][j] = love.math.random() * 2 - 1
        end
    end



    return attractionMatrix
end

local particles = {}
local attractionMatrix = createAttractionMatrix()
local frictionHalfLife = 0.04
local maxRadius = 0.2
local forceFactor = 10

local canvas = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight()
)

local blurCanvas = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight()
)
local hblurCanvas = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight()
)
local vblurCanvas = love.graphics.newCanvas(
    love.graphics.getWidth(),
    love.graphics.getHeight()
)

local h_blur = love.graphics.newShader("h_blur.glsl")
local v_blur = love.graphics.newShader("v_blur.glsl")

local isRunning = true

local function force(r, a)
    local beta = 0.3

    if (r < beta) then
        return r / beta - 1
    elseif (beta < r and r < 1) then
        return a * (1 - math.abs(2 * r - 1 - beta) / (1 - beta))
    else
        return 0
    end
end

local function createParticle(x, y, kind)
    local particle = {
        x = x,
        y = y,
        vx = 0,
        vy = 0,
        kind = kind,
    }

    table.insert(particles, particle)
end

for _ = 1, 1500 do
    local x = love.math.random()
    local y = love.math.random()

    local kind = math.floor(love.math.random() * #colors) + 1

    createParticle(x, y, kind)
end

function love.update(dt)
    if (isRunning) then
        return
    end

    -- if love.keyboard.isDown("a") then
    dt = 0.01
    -- end

    -- dt = math.min(1 / 60, 100)

    local frictionFactor = math.pow(0.5, dt / frictionHalfLife)

    for _, particle in ipairs(particles) do
        local forceX = 0
        local forceY = 0

        for _, oparticle in ipairs(particles) do
            if (particle == oparticle) then
                goto continue
            end

            local dx = oparticle.x - particle.x
            local dy = oparticle.y - particle.y

            dx = dx - 1 * math.floor((dx + 1 / 2) / 1)
            dy = dy - 1 * math.floor((dy + 1 / 2) / 1)

            local distance = math.sqrt(dx * dx + dy * dy)

            if (distance > 0 and distance < maxRadius) then
                local f = force(distance / maxRadius, attractionMatrix[particle.kind][oparticle.kind])

                forceX = forceX + dx / distance * f
                forceY = forceY + dy / distance * f
            end

            ::continue::
        end

        forceX = forceX * maxRadius * forceFactor
        forceY = forceY * maxRadius * forceFactor

        particle.vx = particle.vx * frictionFactor
        particle.vy = particle.vy * frictionFactor

        particle.vx = particle.vx + forceX * dt
        particle.vy = particle.vy + forceY * dt
    end

    for _, particle in ipairs(particles) do
        particle.x = particle.x + particle.vx * dt
        particle.y = particle.y + particle.vy * dt

        if (particle.x > 1) then particle.x = particle.x - 1 end
        if (particle.x < 0) then particle.x = particle.x + 1 end
        if (particle.y > 1) then particle.y = particle.y - 1 end
        if (particle.y < 0) then particle.y = particle.y + 1 end
    end
end

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    for _, particle in ipairs(particles) do
        love.graphics.setColor(colors[particle.kind])
        love.graphics.circle(
            "fill",
            particle.x * love.graphics.getWidth(),
            particle.y * love.graphics.getHeight(),
            4
        )
    end

    love.graphics.setCanvas(blurCanvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("lighten", "premultiplied")
    for _, particle in ipairs(particles) do
        love.graphics.setColor(colors[particle.kind])
        love.graphics.circle(
            "fill",
            particle.x * love.graphics.getWidth(),
            particle.y * love.graphics.getHeight(),
            30
        )
    end
    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setCanvas(hblurCanvas)
    love.graphics.setShader(h_blur)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(blurCanvas)
    love.graphics.setShader()
    love.graphics.setCanvas()
    
    love.graphics.setCanvas(vblurCanvas)
    love.graphics.setShader(v_blur)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.draw(hblurCanvas)
    love.graphics.setShader()
    love.graphics.setCanvas()
    
    love.graphics.setCanvas()

    love.graphics.clear(0.05, 0.05, 0.05, 0)

    love.graphics.setColor(1, 1, 1, 0.1)
    love.graphics.draw(vblurCanvas)
    
    -- love.graphics.setBlendMode("lighten", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas, 0, 0, 0)

end

function love.keypressed(key)
    if (key == "space") then
        isRunning = not isRunning
    end
end
