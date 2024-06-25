local renderer = {}

renderer.cols = 64
renderer.rows = 32
renderer.scale = 10

renderer.display = {}

function renderer:InitializeDisplay()
    for i = 1, self.cols * self.rows do
        self.display[i] = false
    end
end

function renderer:SetPixel(x, y)
    if x > self.cols then
        x = x - self.cols
    elseif x < 0 then
        x = x + self.cols
    end

    if y > self.rows then
        y = y - self.rows
    elseif y < 0 then
        y = y + self.rows
    end

    local pixelLocation = x + (y * self.cols)
    self.display[pixelLocation + 1] = not self.display[pixelLocation + 1]

    return not self.display[pixelLocation + 1]
end

function renderer:Render()
    for i = 1, self.cols * self.rows do
        local x = (i % self.cols) * self.scale
        local y = math.floor(i / self.cols) * self.scale
        
        if self.display[i] == true then
            love.graphics.rectangle("fill", x, y, self.scale, self.scale)
        end
    end
end

return renderer