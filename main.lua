local cols = 64
local rows = 32
local scale = 10

local display = {}

local fps = 60
local fpsInterval, startTime, now, after, elapsed

function SetPixel(x, y)
    if x > cols then
        x = x - cols
    elseif x < 0 then
        x = x + cols
    end
    
    if y > rows then
        y = y - rows
    elseif y < 0 then
        y = y + rows
    end

    local pixelLocation = x + (y * cols) + 1

    if display[pixelLocation] == true then
        display[pixelLocation] = false
    else
        display[pixelLocation] = true
    end
    
    return not display[pixelLocation]
end

function Clear()
    display = {}
end

function RenderDisplay()
    for i = 1, cols * rows do
        local x = (i % cols) * scale
        local y = math.floor(i / cols) * scale

        if display[i] then
            love.graphics.rectangle("fill", x - scale, y, scale, scale)
        end
    end
end

function love.load()
    fpsInterval = 1000 / fps
    after = love.timer.getTime()
    startTime = after
end

function love.update()
    now = love.timer.getTime()
    elapsed = now - after

    if elapsed > fpsInterval then
        
    end
end

function love.draw()
    RenderDisplay()
end
