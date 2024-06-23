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

local memory = {} -- 4kb memory
local v = {} -- registers
local i = 0 -- stores memory address

local delayTimer = 0
local soundTimer = 0

local pc = 0x200 -- program counter

local stack = {}

local paused = false
local speed = 10

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
    for index = 1, cols * rows do
        local x = (index % cols) * scale
        local y = math.floor(index / cols) * scale

        if display[index] then
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

function LoadSpritesIntoMemory() 
    local sprites = {
        0xF0, 0x90, 0x90, 0x90, 0xF0, -- 0
        0x20, 0x60, 0x20, 0x20, 0x70, -- 1
        0xF0, 0x10, 0xF0, 0x80, 0xF0, -- 2
        0xF0, 0x10, 0xF0, 0x10, 0xF0, -- 3
        0x90, 0x90, 0xF0, 0x10, 0x10, -- 4
        0xF0, 0x80, 0xF0, 0x10, 0xF0, -- 5
        0xF0, 0x80, 0xF0, 0x90, 0xF0, -- 6
        0xF0, 0x10, 0x20, 0x40, 0x40, -- 7
        0xF0, 0x90, 0xF0, 0x90, 0xF0, -- 8
        0xF0, 0x90, 0xF0, 0x10, 0xF0, -- 9
        0xF0, 0x90, 0xF0, 0x90, 0x90, -- A
        0xE0, 0x90, 0xE0, 0x90, 0xE0, -- B
        0xF0, 0x80, 0x80, 0x80, 0xF0, -- C
        0xE0, 0x90, 0x90, 0x90, 0xE0, -- D
        0xF0, 0x80, 0xF0, 0x80, 0xF0, -- E
        0xF0, 0x80, 0xF0, 0x80, 0x80  -- F
    }

    for i = 1, #sprites do
        memory[i] = sprites[i]
    end
end

function LoadProgramIntoMemory(program)
    for loc = 1, string.len(program) do
        memory[0x200 + loc] = string.byte(program, loc, loc)
    end
end

function LoadRom(romName)
    local contents = love.filesystem.read("string", romName, math.huge)

    LoadProgramIntoMemory(contents)
end

function ExecuteInstruction(opcode)
    pc = pc + 2
    
    local x = bit.rshift(bit.band(opcode, 0x0F00), 8)
    local y = bit.lshift(bit.band(opcode, 0x00F0), 4)

    -- there is no swich statement in lua please forgive me

    local instruction = bit.band(opcode, 0xF000)

    if instruction == 0x000 then
        if opcode == 0x00E0 then
            Clear()
        elseif opcode == 0x00EE then
            pc = stack[#stack]
            pc = table.remove(stack, #stack)
        end
    elseif instruction == 0x1000 then
        pc = bit.band(opcode, 0xFFF)
    elseif instruction == 0x2000 then
        table.insert(stack, pc)
        pc = bit.band(opcode, 0xFFF)
    elseif instruction == 0x3000 then
    elseif instruction == 0x4000 then
    elseif instruction == 0x5000 then
    elseif instruction == 0x6000 then
    elseif instruction == 0x7000 then
    elseif instruction == 0x8000 then
        if bit.band(opcode, 0xF) == 0x0 then
        elseif bit.band(opcode, 0xF) == 0x0 then
        elseif bit.band(opcode, 0xF) == 0x1 then
        elseif bit.band(opcode, 0xF) == 0x2 then
        elseif bit.band(opcode, 0xF) == 0x3 then
        elseif bit.band(opcode, 0xF) == 0x4 then
        elseif bit.band(opcode, 0xF) == 0x5 then
        elseif bit.band(opcode, 0xF) == 0x6 then
        elseif bit.band(opcode, 0xF) == 0x7 then
        elseif bit.band(opcode, 0xF) == 0xE then
        end
    elseif instruction == 0x9000 then
    elseif instruction == 0xA000 then
    elseif instruction == 0xB000 then
    elseif instruction == 0xC000 then
    elseif instruction == 0xD000 then
    elseif instruction == 0xE000 then
    elseif instruction == 0xF000 then
        if bit.band(opcode, 0xFF) == 0x07 then
        elseif bit.band(opcode, 0xFF) == 0x0A then
        elseif bit.band(opcode, 0xFF) == 0x15 then
        elseif bit.band(opcode, 0xFF) == 0x18 then
        elseif bit.band(opcode, 0xFF) == 0x1E then
        elseif bit.band(opcode, 0xFF) == 0x29 then
        elseif bit.band(opcode, 0xFF) == 0x33 then
        elseif bit.band(opcode, 0xFF) == 0x55 then
        elseif bit.band(opcode, 0xFF) == 0x65 then
        end
    else
        error("Unknown opcode: "..tostring(opcode))
    end
end

function Cycle()
    for i = 1, speed do
        if not paused then
            local opcode = bit.bor(bit.lshift(memory[pc], 8), memory[pc + 1])
            
        end
    end

    if not paused then
        if delayTimer > 0 then
            delayTimer = delayTimer - 1
        end

        if soundTimer > 0 then
            soundTimer = soundTimer - 1
        end
    end

    RenderDisplay()
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
