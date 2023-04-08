-- A tapper clone because I liked tapper in the arcade

COLOR_TABLE = {
    165 / 255,
    42 / 255,
    42 / 255,
    1
}

print (COLOR_TABLE)

Lane = {}
Lane.__index = Lane

function Lane:new (o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Lane:draw()
    -- draw the bar table
    love.graphics.setColor(COLOR_TABLE)
    love.graphics.rectangle("fill", 0, self.y, 900, 100)

    -- draw the taps
    love.graphics.rectangle("fill", 950, self.y - 50, 50, 100)
end

function Lane:spawnPatrons() 
end


lanes = {
    Lane:new{y=200},
    Lane:new{y=350},
    Lane:new{y=500},
    Lane:new{y=650}
}

print(lanes)

function love.load() 
end

function love.draw() 
    for k, v in ipairs(lanes) do
        v:draw()
    end
end

function love.update(dt) 
end