local cpu = {}

cpu.renderer = require("renderer")
cpu.keyboard = require("keyboard")

cpu.memory = {}
cpu.v = {}
cpu.i = 0

cpu.delayTimer = 0
cpu.soundTimer = 0

cpu.pc = 0x200

cpu.stack = {}

cpu.paused = false
cpu.speed = 10

function cpu:LoadSpritesIntoMemory()
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
    
    for i = 0, #sprites do
        self.memory[i] = sprites[i]
    end
end

function cpu:LoadRom()
    local program = love.filesystem.read("/roms/TETRIS.ch8")

    local instructions = {}

    local i = 1
    local length = string.len(program)

    while i <= length do
        local a, b = program:byte(i, i + 1)
        i = i + 2
        
        table.insert(instructions, a * 16 * 16 + (b or 0))
    end

    local p = 0x200

    for _, instruction in ipairs(instructions) do
        self.memory[p] = bit.rshift(instruction, 8)
        self.memory[p + 1] = bit.band(instruction, 0xFF)
        p = p + 2
    end

    for i = 0, 0x1FF do
        self.memory[i] = 0
    end

    self:LoadSpritesIntoMemory()
end

function cpu:Cycle()
    local byte1 = self.memory[self.pc] or 0
    local byte2 = self.memory[self.pc + 1] or 0

    local word = byte1 * 16 * 16 + byte2

    local nnn = bit.band(word, 0x0fff)
    local kk = byte2
    local o = bit.rshift(bit.band(byte1, 0xf0), 4)
    local x = bit.band(byte1, 0x0f)
    local y = bit.rshift(bit.band(byte2, 0xf0), 4)
    local n = bit.band(byte2, 0x0f)

    if o == 0x0 then
        if kk == 0x00E0 then -- clear display
            self.renderer:InitializeDisplay()
        elseif kk == 0x00EE then -- return from subroutine
            self.pc = table.remove(self.stack) + 2
        end

        self.pc = self.pc + 2
    elseif o == 0x1 then -- jump to nnn
        self.pc = nnn
    elseif o == 0x2 then -- call subroutine at nnn
        table.insert(self.stack, self.pc)
        self.pc = nnn
    elseif o == 0x3 then -- skip instruction if V[x] equals kk
        if self.v[x] == kk then
            self.pc = self.pc + 4
        else
            self.pc = self.pc + 2
        end
    elseif o == 0x4 then -- skip instruction if V[x] does not equal kk
        if self.v[x] ~= kk then
            self.pc = self.pc + 4
        else
            self.pc = self.pc + 2
        end
    elseif o == 0x5 then -- skip instruction if V[x] does not equal V[y]
        if self.v[x] ~= self.v[y] then
            self.pc = self.pc + 4
        else
            self.pc = self.pc + 2
        end
    elseif o == 0x6 then -- set V[x] to kk
        self.v[x] = kk
        self.pc = self.pc + 2
    elseif o == 0x7 then -- add kk to V[x]
        local val = cpu.v[x] + kk

        if val > 0xFF then
            v = v - 0x100
        end

        self.v[x] = v
        self.pc = self.pc + 2
    elseif o == 0x8 then 
        if n == 0x0 then -- set V[x] to V[y]
            self.v[x] = self.v[y]
        elseif n == 0x1 then -- set V[x] to v[x] or v[y]
            self.v[x] = bit.bor(self.v[x], self.v[y])
        elseif n == 0x2 then
            self.v[x] = bit.band(self.v[x], self.v[y])
        elseif n == 0x3 then
            self.v[x] = bit.bxor(self.v[x], self.v[y])
        elseif n == 0x4 then
            local val = self.v[x] + self.v[y]
            self.v[0xF] = 0
            
            if val > 0xFF then
                val = val - 0x100
                self.v[0xF] = 1
            end
            self.v[x] = val
        elseif n == 0x5 then
            local val = self.v[x] - self.v[y]
            self.v[0xF] = 1
            
            if val < 0 then
                val = val + 0x100
                self.v[0xF] = 0
            end
            self.v[x] = val
        elseif n == 0x6 then
            self.v[0xF] = bit.band(0x1, self.v[y])
            self.v[x] = bit.rshift(self.v[y], 1)
        elseif n == 0x7 then
            local val = self.v[y] - self.v[x]
            self.v[0xF] = 1

            if val < 0 then
                val = val + 0x100
                self.v[0xF] = 1
            end
            self.v[x] = val
        elseif n == 0xE then
            self.v[0xF] = bit.rshift(self.v[y], 7)
            self.v[x] = bit.band(0xFF, bit.lshift(self.v[y], 1))
        end
        
        self.pc = self.pc + 2
    elseif o == 0x9 then
        if self.v[x] ~= self.v[y] then
            self.pc = self.pc + 4
        else
            self.pc = self.pc + 2
        end
    elseif o == 0xA then
        self.i = nnn
        self.pc = self.pc + 2
    elseif o == 0xB then
        self.pc = nnn + v[0x0]
    elseif o == 0xC then
        v[x] = bit.band(math.random(0, 0xFF), kk)
        self.pc = self.pc + 2
    elseif o == 0xD then
        local width = 8
        local height = n
        
        self.v[0xF] = 0
        
        for row = 0, height - 1 do
            local sprite = self.memory[self.i + row] or 0

            for col = 0, width - 1 do
                if bit.band(sprite, 0x80) > 0 then
                    if self.renderer:SetPixel(self.v[x] + col, self.v[y] + row) then
                        self.v[0xF] = 1
                    end
                end

                sprite = bit.lshift(sprite, 1)
            end
        end
    elseif o == 0xE then
        if kk == 0x9E then
            self.pc = self.pc + 2
        elseif kk == 0xA1 then
            self.pc = self.pc + 2
        end
    elseif o == 0xF then
        if kk == 0x07 then
            self.v[x] = self.delayTimer
        elseif kk == 0x0A then
            self.onNextKeyPress = x
        elseif kk == 0x15 then
            self.delayTimer = self.v[x]
        elseif kk == 0x18 then
            self.soundTimer = self.v[x]
        elseif kk == 0x1E then
            self.i = self.i + self.v[x]
        elseif kk == 0x29 then
            self.i = self.v[x] * 5
        elseif kk == 0x33 then
            local number = self.v[x]

            self.memory[self.i + 0] = math.floor(number / 100)
            number = number % 100
            self.memory[self.i + 1] = math.floor(number / 10)
            number = number % 10
            self.memory[self.i + 2] = number
        elseif kk == 0x55 then
            for index = 0, x do
                self.memory[self.i] = self.v[index]
                self.i = self.i + 1
            end
        elseif kk == 0x65 then
            for index = 0, x do
                self.v[index] = self.memory[self.i]
                self.i = self.i + 1
            end
        end

        self.pc = self.pc + 2
    end
end

return cpu