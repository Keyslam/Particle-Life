-- Poisson Disc Sampling in Lua
-- This implementation uses Bridson's algorithm for Poisson disc sampling

local sqrt, cos, sin, pi, random = math.sqrt, math.cos, math.sin, math.pi, math.random

-- Utility function to create a grid for storing samples
local function createGrid(width, height, cellSize)
    local gridWidth = math.ceil(width / cellSize)
    local gridHeight = math.ceil(height / cellSize)
    local grid = {}
    for i = 1, gridWidth do
        grid[i] = {}
        for j = 1, gridHeight do
            grid[i][j] = nil
        end
    end
    return grid, gridWidth, gridHeight
end

-- Function to add a sample to the grid
local function insertSample(grid, cellSize, sample)
    local x, y = sample[1], sample[2]
    local gx = math.floor(x / cellSize) + 1
    local gy = math.floor(y / cellSize) + 1
    grid[gx][gy] = sample
end

-- Function to generate random point around a given point
local function generateRandomPointAround(point, minDist)
    local r1 = random()
    local r2 = random()
    local radius = minDist * (r1 + 1)
    local angle = 2 * pi * r2
    local newX = point[1] + radius * cos(angle)
    local newY = point[2] + radius * sin(angle)
    return { newX, newY }
end

-- Function to check if a point is valid (inside bounds and not too close to other points)
local function isValidPoint(grid, width, height, cellSize, sample, minDist)
    local x, y = sample[1], sample[2]
    if x < 0 or y < 0 or x >= width or y >= height then
        return false
    end
    local gx = math.floor(x / cellSize) + 1
    local gy = math.floor(y / cellSize) + 1
    local minDistSquared = minDist * minDist
    for i = -1, 1 do
        for j = -1, 1 do
            local neighborX = gx + i
            local neighborY = gy + j
            if grid[neighborX] and grid[neighborX][neighborY] then
                local neighbor = grid[neighborX][neighborY]
                local dx = neighbor[1] - x
                local dy = neighbor[2] - y
                if dx * dx + dy * dy < minDistSquared then
                    return false
                end
            end
        end
    end
    return true
end

-- Main function for Poisson disc sampling
local function poissonDiscSampling(width, height, minDist, k)
    local cellSize = minDist / sqrt(2)
    local grid, gridWidth, gridHeight = createGrid(width, height, cellSize)
    local processList = {}
    local samples = {}

    -- Initial sample
    local initialSample = { random() * width, random() * height }
    table.insert(processList, initialSample)
    table.insert(samples, initialSample)
    insertSample(grid, cellSize, initialSample)

    while #processList > 0 do
        local idx = random(#processList)
        local sample = table.remove(processList, idx)

        for i = 1, k do
            local newSample = generateRandomPointAround(sample, minDist)
            if isValidPoint(grid, width, height, cellSize, newSample, minDist) then
                table.insert(processList, newSample)
                table.insert(samples, newSample)
                insertSample(grid, cellSize, newSample)
            end
        end
    end

    return samples
end

return poissonDiscSampling
