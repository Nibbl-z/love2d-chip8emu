local renderer = require("renderer")

function love.load()
    renderer:InitializeDisplay()
end

function love.update()
    
end

function love.draw()
    renderer:Render()
end