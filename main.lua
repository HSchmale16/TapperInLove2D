-- A tapper clone because I liked tapper in the arcade, and was inspired
-- Henry J Schmale
-- April 8, 2023

-- ------------------------------------------------------
-- VARIOUS LIBRARY IMPORTS
-- ------------------------------------------------------

inspect = require('inspect')


-- ------------------------------------------------------
-- BEGIN VARIOUS CONSTANTS
-- ------------------------------------------------------
COLOR_TABLE = {165 / 255, 42 / 255, 42 / 255, 1}

COLOR_BARKEEP = {0, 1, 1, 1}

-- lightgoldenrodyellow
COLOR_MUG = {250 / 255, 250 / 255, 210 / 255}

-- saddlebrown
COLOR_BEER = {139 / 255, 69 / 255, 19 / 255}

COLOR_PATRON = {0, 1, 0}

MUG_HEIGHT = 30
MUG_WIDTH = 15

-- ------------------------------------------------------
-- Begin the lane definitions
-- ------------------------------------------------------

Lane = {}
Lane.__index = Lane

function Lane:new (o)
    local l = {
        y = 0,
        barkeep_here = false,
        mugs = {},
        TABLE_END = 900,
        patrons = {}
    }

    for k, v in pairs(o) do
        l[k] = v
    end

    setmetatable(l, self)
    self.__index = self

    return l
end

function Lane:draw()
    -- patrons are always beneth the tables
    love.graphics.setColor(COLOR_PATRON)
    for k, v in ipairs(self.patrons) do
        love.graphics.rectangle("fill", v.x, self.y - 15 - v.y, 15, 30)
    end

    -- draw the bar table
    love.graphics.setColor(COLOR_TABLE)
    love.graphics.rectangle("fill", 0, self.y, self.TABLE_END, 80)

    -- draw the taps
    love.graphics.rectangle("fill", 990, self.y - 50, 100, 100)
    love.graphics.rectangle("fill", 975, self.y - 14, 20, 7)

    -- draw the bartender if here
    if self.barkeep_here then
        love.graphics.setColor(COLOR_BARKEEP)
        love.graphics.rectangle("fill", 910, self.y-25, 50, 75)

        if MUGFILL_IN_PROGRESS or MUGFILL_PERCENT > 0 then  
            local y = self.y + 2
            local height = (MUGFILL_PERCENT / 100) * 30
            local y2 = y + (30 - height)

            -- mug fill
            love.graphics.setColor(COLOR_BEER)
            love.graphics.rectangle("fill", 965, y2, 15, height)

            -- mug outline
            love.graphics.setColor(COLOR_MUG)
            love.graphics.rectangle("line", 965, self.y + 2, MUG_WIDTH, MUG_HEIGHT)
        end
    end

    -- draw any mugs
    -- drawn with 2 loops to reduce number of color set calls
    love.graphics.setColor(COLOR_BEER)
    for k, v in ipairs(self.mugs) do
        love.graphics.rectangle("fill", v.x, self.y - MUG_HEIGHT, MUG_WIDTH, MUG_HEIGHT)
    end

    love.graphics.setColor(COLOR_MUG)
    for k, v in ipairs(self.mugs) do
        love.graphics.rectangle("line", v.x, self.y - MUG_HEIGHT, MUG_WIDTH, MUG_HEIGHT)
    end
end


function Lane:updateMugs(dt) 
    local distance = 20 * dt
    for k, v in pairs(self.mugs) do
        v.x = v.x - distance
    end
end

function Lane:updatePatrons(dt) 
    for k, v in ipairs(self.patrons) do
        v.x = v.x + 30 * dt
        v.y = v.y + v.dy * dt
        if v.y > 7 or v.y < 0 then
            v.dy = v.dy * -1
        end
    end
end

function Lane:update(dt)
    self:updateMugs(dt)
    self:updatePatrons(dt)
end

function Lane:sendMug()
    table.insert(self.mugs, {
        x = self.TABLE_END - MUG_WIDTH
    })
end

function Lane:spawnPatron()
    table.insert(self.patrons, {
        x  = 0,
        y  = love.math.random(0, 4),
        dy = love.math.random(6, 8),
        sprite = 0,
        beers_required = love.math.random(2)
    })
end


-- ------------------------------------------------------
-- BEGIN GAME LOGIC
-- ------------------------------------------------------

lanes = {
    Lane:new{y=200, barkeep_here=true},
    Lane:new{y=350},
    Lane:new{y=500},
    Lane:new{y=650}
}

-- where the players is. Which lane
BARKEEP_INDEX = 1

-- Mug filling tracking vars cause tapper is weird about filling.
MUGFILL_IN_PROGRESS = true
MUGFILL_PERCENT = 0

-- Patron spawning counter
PATRON_COUNTS = {1.5, 2, 1.35, 2.25}
PATRON_PATTERN = 1
PATRON_SPAWNED_LAST = 1
PATRON_COUNTER = 0

function love.load() 
end

function love.draw() 
    for k, v in ipairs(lanes) do
        v:draw()
    end

    txt = string.format("score = %d fps = %d", 0, love.timer.getFPS())
    love.graphics.print(txt, 10, 10)
end

function love.update(dt)
    -- update the lanes
    for k, v in ipairs(lanes) do 
        v:update(dt)
    end

    -- handle filling mug
    if MUGFILL_IN_PROGRESS and MUGFILL_PERCENT < 100 then
        MUGFILL_PERCENT = MUGFILL_PERCENT + 105 * dt
    end

    -- handle spawning patrons
    PATRON_COUNTER = PATRON_COUNTER + dt
    if PATRON_COUNTER > PATRON_COUNTS[PATRON_PATTERN] then
        PATRON_COUNTER = 0
        PATRON_PATTERN = love.math.random(#PATRON_COUNTS)
        local spawn_lane = love.math.random(#lanes)
        lanes[spawn_lane]:spawnPatron()
    end
end

function love.keypressed(key, scancode, isrepeat) 
    if key == 'a' then
        finishMugFill()
        -- move barkeep down
        lanes[BARKEEP_INDEX].barkeep_here = false
        BARKEEP_INDEX = (BARKEEP_INDEX + 1) % (#lanes + 1)
        if BARKEEP_INDEX == 0 then
            BARKEEP_INDEX = 1
        end
        lanes[BARKEEP_INDEX].barkeep_here = true

    elseif key == 'd' then
        -- move barkeep up
        finishMugFill()
        lanes[BARKEEP_INDEX].barkeep_here = false
        BARKEEP_INDEX = (BARKEEP_INDEX - 1) % (#lanes + 1)
        if BARKEEP_INDEX == 0 then
            BARKEEP_INDEX = 4
        end
        lanes[BARKEEP_INDEX].barkeep_here = true
    elseif key == 's' then
        -- start fill while held
        MUGFILL_IN_PROGRESS = true
    end
end

function love.keyreleased(key, scancode, isrepeat)
    if key == 's' then
        -- mugfill is over
        MUGFILL_IN_PROGRESS = false

        if MUGFILL_PERCENT >= 100 then
            finishMugFill()
        end
    end
end

function finishMugFill()
    if MUGFILL_PERCENT >= 100 then
        local item = lanes[BARKEEP_INDEX]
        item:sendMug()
    end
    MUGFILL_PERCENT = 0
    MUGFILL_IN_PROGRESS = false
end
