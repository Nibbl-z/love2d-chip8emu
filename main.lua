local renderer = require("renderer")
local cpu = require("cpu")
function love.load()
    renderer:InitializeDisplay()
    cpu:LoadRom()
end

function love.update()
    cpu:Cycle()
end

function love.draw()
    renderer:Render()
end