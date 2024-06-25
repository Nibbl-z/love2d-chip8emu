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
    end
end

return cpu