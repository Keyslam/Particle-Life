local colors = {
    { love.math.colorFromBytes(234, 89, 89) },
    { love.math.colorFromBytes(234, 168, 86) },
    { love.math.colorFromBytes(239, 215, 127) },
    { love.math.colorFromBytes(143, 217, 86) },
    { love.math.colorFromBytes(99, 216, 162) },
    { love.math.colorFromBytes(73, 142, 188) },
    { love.math.colorFromBytes(106, 85, 209) },
}

local gradient = love.graphics.newImage("Gradient.png")

local canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getHeight())

local shader = love.graphics.newShader([[
    vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);

    if (texturecolor.a > 0.3f) {
       return vec4(texturecolor.rgb, 1.0f);
    }

    return vec4(0.0f);
}
]])

function love.draw()
    love.graphics.setCanvas(canvas)
    love.graphics.setShader()
    love.graphics.clear(0, 0, 0, 0)
    
    love.graphics.setBlendMode("screen", "premultiplied")

    love.graphics.setColor(1, 0, 0, 1)
    love.graphics.draw(gradient, 1080/2 - 30 + math.sin(love.timer.getTime() * 2) * 30 - 32, 1080/2 - 32)

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.draw(gradient, 1080/2 + 30 - math.sin(love.timer.getTime() * 2) * 30 - 32, 1080/2 - 32)

    love.graphics.setCanvas()
    love.graphics.setShader(shader)

    love.graphics.setBlendMode("alpha", "alphamultiply")
    love.graphics.draw(canvas)
end
