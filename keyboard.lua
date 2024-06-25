local keyboard = {}

keyboard.keymap = {
    ["1"] = 0x1, 
    ["2"] = 0x2, 
    ["3"] = 0x3, 
    ["4"] = 0xC,
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
    ["v"] = 0xF,
}

keyboard.keysPressed = {}
keyboard.onNextKeyPress = nil

function keyboard:IsKeyPressed(keycode)
    return self.keysPressed[keycode]
end

function love.keypressed(_, scancode, isRepeat)
    if isRepeat then return end

    local key = keyboard.keymap[scancode]
    keyboard.keysPressed[key] = true
    
    if keyboard.onNextKeyPress ~= nil and key ~= nil then
        keyboard.onNextKeyPress(key)
        keyboard.onNextKeyPress = nil
    end
end

function love.keyreleased(_, scancode)
    local key = keyboard.keymap[scancode]
    keyboard.keysPressed[key] = false
end

return keyboard