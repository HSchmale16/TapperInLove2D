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
COLOR_TABLE = {
    165 / 255,
    42 / 255,
    42 / 255,
    1
}

COLOR_BARKEEP = {
    0,
    1,
    1,
    1
}

COLOR_MUG = {
    250 / 255,
    250 / 255,
    210 / 255
    -- lightgoldenrodyellow
}

COLOR_BEER = {
    139 / 255,
    69 / 255,
    19 / 255
}

-- ------------------------------------------------------
-- Begin the lane definitions
-- ------------------------------------------------------

Lane = {}
Lane.__index = Lane

function Lane:new (o)
    local l = {
        y = 0,
        barkeep_here = false
    }
    -- print(inspect(o))

    for k, v in pairs(o) do
        l[k] = v
    end

    setmetatable(l, self)
    self.__index = self

    print(inspect(l))
    return l
end

function Lane:draw()
    -- draw the bar table
    love.graphics.setColor(COLOR_TABLE)
    love.graphics.rectangle("fill", 0, self.y, 900, 80)

    -- draw the taps
    love.graphics.rectangle("fill", 990, self.y - 50, 100, 100)
    love.graphics.rectangle("fill", 975, self.y - 10, 20, 10)

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
            love.graphics.rectangle("line", 965, self.y + 2, 15, 30)
        end
    end
end

function Lane:spawnPatrons()
end

function Lane:updateMugs() 
end

function Lane:update(dt)
    self.spawnPatrons()
    self.updateMugs()
end

function Lane:sendMug()
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

BARKEEP_INDEX = 1
MUGFILL_IN_PROGRESS = true
MUGFILL_PERCENT = 0

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
    for k, v in ipairs(lanes) do 
        v:update(dt)
    end

    if MUGFILL_IN_PROGRESS and MUGFILL_PERCENT < 100 then
        MUGFILL_PERCENT = MUGFILL_PERCENT + 75 * dt
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
        lanes[BARKEEP_INDEX].sendMug()
    end
    MUGFILL_PERCENT = 0
    MUGFILL_IN_PROGRESS = false
end
