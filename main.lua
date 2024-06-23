local cols = 64
local rows = 32
local scale = 10

local display = {}

local fps = 60
local fpsInterval, startTime, now, after, elapsed

local keymap = {
    ["1"] = 0x1,
    ["2"] = 0x2,
    ["3"] = 0x3,
    ["4"] = 0xc,
    ["q"] = 0x4,
    ["w"] = 0x5,
    ["e"] = 0x6,
    ["r"] = 0xD,
    ["a"] = 0x7,
    ["s"] = 0x8,
    ["d"] = 0x9,
    ["f"] = 0xE,
    ["z"] = 0xA,
    ["x"] = 0x0,
    ["c"] = 0xB,
    ["v"] = 0xF
}

local keysPressed = {}
local onNextKeyPress = nil

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

function IsKeyPressed(keyCode)
    return keysPressed[keyCode]
end

function love.keypressed(_, scancode)
    local hexKey = keymap[scancode]
    if hexKey == nil then return end
    keysPressed[hexKey] = true

    if onNextKeyPress ~= nil and hexKey ~= nil then
        onNextKeyPress(tonumber(hexKey))
        onNextKeyPress = nil
    end
end

function love.keyreleased(_, scancode)
    local key = keymap[scancode]
    keysPressed[key] = false
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
