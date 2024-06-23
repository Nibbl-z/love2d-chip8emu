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
    local contents = love.filesystem.read("string", "roms/"..romName)
    
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
        if v[x] == bit.band(opcode, 0xFF) then
            pc = pc + 2
        end
    elseif instruction == 0x4000 then
        if v[x] ~= bit.band(opcode, 0xFF) then
            pc = pc + 2
        end
    elseif instruction == 0x5000 then
        if v[x] == v[y] then
            pc = pc + 2
        end
    elseif instruction == 0x6000 then
        v[x] = bit.band(opcode, 0xFF)
    elseif instruction == 0x7000 then
        v[x] = v[x] + bit.band(opcode, 0xFF)
    elseif instruction == 0x8000 then
        if bit.band(opcode, 0xF) == 0x0 then
            v[x] = v[y]
        elseif bit.band(opcode, 0xF) == 0x1 then
            v[x] = bit.bor(v[x], v[y])
        elseif bit.band(opcode, 0xF) == 0x2 then
            v[x] = bit.band(v[x], v[y])
        elseif bit.band(opcode, 0xF) == 0x3 then
            v[x] = bit.bxor(v[x], v[y])
        elseif bit.band(opcode, 0xF) == 0x4 then -- v not being an 8bit array might cause issues... but thats a problem for later!!
            local sum = v[x] + v[y]
            v[0xF] = 0

            if sum > 0xFF then
                v[0xF] = 1
            end

            v[x] = sum
        elseif bit.band(opcode, 0xF) == 0x5 then -- same here
            v[0xF] = 0

            if v[x] > v[y] then
                v[0xF] = 1
            end

            v[x] = v[x] - v[y]
        elseif bit.band(opcode, 0xF) == 0x6 then
            v[0xF] = bit.band(v[x], 0x1)
            v[x] = bit.rshift(v[x], 1)
        elseif bit.band(opcode, 0xF) == 0x7 then
            v[0xF] = 0

            if v[y] > v[x] then
                v[0xF] = 1
            end

            v[x] = v[y] - v[x]
        elseif bit.band(opcode, 0xF) == 0xE then
            v[0xF] = bit.band(v[x], 0x80)
            v[x] = bit.lshift(v[x], 1)
        end
    elseif instruction == 0x9000 then
        if v[x] ~= v[y] then
            pc = pc + 2
        end
    elseif instruction == 0xA000 then
        i = bit.band(opcode, 0xFFF)
    elseif instruction == 0xB000 then
        pc = bit.band(opcode, 0xFFF) + v[0]
    elseif instruction == 0xC000 then
        local rand = math.random(0, 255)
        v[x] = bit.band(rand, bit.band(opcode, 0xFF))
    elseif instruction == 0xD000 then
        local width = 8
        local height = bit.band(opcode, 0xF)

        v[0xF] = 0

        for row = 1, height do
            local sprite = memory[i + row]

            for col = 1, width do
                if bit.band(sprite, 0x80) > 0 then
                    if SetPixel(v[x] + col, v[y] + row) then
                        v[0xF] = 1
                    end
                end
                
                sprite = bit.lshift(sprite, 1)
            end
        end
    elseif instruction == 0xE000 then
        if bit.band(opcode, 0xFF) == 0x9E then
            if IsKeyPressed(v[x]) then
                pc = pc + 2
            end
        elseif bit.band(opcode, 0xFF) == 0xA1 then
            if not IsKeyPressed(v[x]) then
                pc = pc + 2
            end
        end
    elseif instruction == 0xF000 then
        if bit.band(opcode, 0xFF) == 0x07 then
            v[x] = delayTimer
        elseif bit.band(opcode, 0xFF) == 0x0A then
            paused = true

            onNextKeyPress = function(key)
                v[x] = key
                paused = false
            end
        elseif bit.band(opcode, 0xFF) == 0x15 then
            delayTimer = v[x]
        elseif bit.band(opcode, 0xFF) == 0x18 then
            soundTimer = v[x]
        elseif bit.band(opcode, 0xFF) == 0x1E then
            i = i + v[x]
        elseif bit.band(opcode, 0xFF) == 0x29 then
            i = v[x] * 5
        elseif bit.band(opcode, 0xFF) == 0x33 then
            memory[i] = tonumber(v[x] / 100)
            memory[i + 1] = tonumber((v[x] % 100) / 10)
            memory[i + 2] = tonumber(v[x] % 10)
        elseif bit.band(opcode, 0xFF) == 0x55 then
            for registerIndex = 1, x do
                memory[i + registerIndex] = v[registerIndex]
            end
        elseif bit.band(opcode, 0xFF) == 0x65 then
            for registerIndex = 1, x do
                v[registerIndex] = memory[i + registerIndex]
            end
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

    LoadSpritesIntoMemory()
    LoadRom("BLITZ")
end

function love.update()
    now = love.timer.getTime()
    elapsed = now - after

    if elapsed > fpsInterval then
        Cycle()
    end
end

function love.draw()
    RenderDisplay()
end
