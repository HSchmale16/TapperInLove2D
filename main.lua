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
COLOR_LEAVING_PATRON = {1, 1, 0}

MUG_HEIGHT = 30
MUG_WIDTH = 20

PATRON_WIDTH = 24

SCORE = 0
LIVES = 3

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
        patrons = {},
        leaving_patrons = {}
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

    love.graphics.setColor(COLOR_LEAVING_PATRON)
    for k, v in ipairs(self.leaving_patrons) do
        love.graphics.rectangle("fill", v.x, self.y - 15 - v.y, 15, 30)
    end

    -- draw the bar table
    love.graphics.setColor(COLOR_TABLE)
    love.graphics.rectangle("fill", 0, self.y, self.TABLE_END, 80)

    if self.barkeep_here then
        love.graphics.setColor(COLOR_BARKEEP)
        love.graphics.rectangle("fill", 910, self.y-25, 50, 75)

        if MUGFILL_IN_PROGRESS or MUGFILL_PERCENT > 0 then  
            local y = self.y + 2
            local height = (MUGFILL_PERCENT / 100) * MUG_HEIGHT
            local y2 = y + (MUG_HEIGHT - height)

            -- mug fill
            love.graphics.setColor(COLOR_BEER)
            love.graphics.rectangle("fill", 965, y2, MUG_WIDTH, height)

            -- the fill spout coming out
            love.graphics.rectangle("fill", 970, self.y - 14, 5, 30)

            -- mug outline
            love.graphics.setColor(COLOR_MUG)
            love.graphics.rectangle("line", 965, self.y + 2, MUG_WIDTH, MUG_HEIGHT)

        end
    end

    -- draw the taps
    love.graphics.setColor(COLOR_TABLE)
    love.graphics.rectangle("fill", 990, self.y - 50, 100, 100)
    love.graphics.rectangle("fill", 965, self.y - 14, 50, 7)

    -- draw the bartender if here
    if self.barkeep_here then
        love.graphics.setColor(COLOR_BARKEEP)
        love.graphics.rectangle("fill", 910, self.y-25, 50, 75)

        if MUGFILL_IN_PROGRESS or MUGFILL_PERCENT > 0 then  
            local y = self.y + 2
            local height = (MUGFILL_PERCENT / 100) * MUG_HEIGHT
            local y2 = y + (MUG_HEIGHT - height)

            -- mug fill
            love.graphics.setColor(COLOR_BEER)
            love.graphics.rectangle("fill", 965, y2, MUG_WIDTH, height)

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
    local distance = 40 * dt
    for k, v in pairs(self.mugs) do
        v.x = v.x - distance
    end
end

function Lane:updatePatrons(dt) 
    for k, v in ipairs(self.patrons) do
        v.x = v.x + v.dx * dt
        v.y = v.y + v.dy * dt
        if v.y > 7 or v.y < 0 then
            v.dy = v.dy * -1
        end
    end

    local to_delete = {}
    for k, v in ipairs(self.leaving_patrons) do
        v.x = v.x + v.dx * dt
        v.y = v.y + v.dy * dt
        if v.y > 7 or v.y < 0 then
            v.dy = v.dy * -1
        end
        if v.x < 0 then
            table.insert(to_delete, k)
        end
    end

    for i=1,#to_delete,1 do
        table.remove(self.leaving_patrons, to_delete[i])
    end
end

function Lane:update(dt)
    self:updateMugs(dt)
    self:updatePatrons(dt)

    -- we only have to test the first mug and first patron to see if they have their beer
    -- if they have any beers remaining they get shoved back.
    -- the score also goes up for matching them.
    -- maybe should update to searching for patrons on a given beer.
    -- Max number of steps will be 5.
    if #self.patrons > 0 and #self.mugs > 0 then
        local patron = self.patrons[1]
        local beer = self.mugs[1]
        if patron.x > beer.x and beer.x < (patron.x + PATRON_WIDTH) then 
            -- the mug is consumed
            table.remove(self.mugs, 1)
            SCORE = SCORE + 100

            patron.beers_required = patron.beers_required - 1
            if patron.beers_required <= 0 then
                -- people who need 0 more beers should be told to go away
                patron.dx = -50

                -- move to leaving_patrons because we don't want to collide with losers
                table.remove(self.patrons, 1)
                table.insert(self.leaving_patrons, patron)
            else
                -- TODO: Cover drinking a beer animation
            end
        end
    end

    if #self.patrons > 0 then
    end

    if #self.mugs > 0 then 
    end
end

function Lane:sendMug()
    table.insert(self.mugs, {
        x = self.TABLE_END - MUG_WIDTH
    })
end

function Lane:spawnPatron()
    table.insert(self.patrons, {
        x  = 0,
        dx = 20,
        y  = love.math.random(0, 4),
        dy = love.math.random(6, 8),
        sprite = 0,
        beers_required = 1
    })
end


-- ------------------------------------------------------
-- BEGIN GAME LOGIC
-- ------------------------------------------------------


-- where the players is. Which lane
BARKEEP_INDEX = 1

-- Mug filling tracking vars cause tapper is weird about filling.
MUGFILL_IN_PROGRESS = true
MUGFILL_PERCENT = 0

-- Patron spawning counter
PATRON_COUNTS = {1.5, 2, 1.5, 2.25}
MAX_PATRONS = 10
PATRON_PATTERN = 1
PATRON_SPAWNED_LAST = 1
PATRON_COUNTER = 0

function love.load() 
    resetGame()
end

function love.draw() 
    for k, v in ipairs(lanes) do
        v:draw()
    end

    txt = string.format("score = %d lives= %d fps = %d", SCORE, LIVES, love.timer.getFPS())
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

    local num_patrons = 0
    for i=1,#lanes,1 do
        num_patrons = num_patrons + #lanes[i].patrons
    end

    -- handle spawning patrons
    PATRON_COUNTER = PATRON_COUNTER + dt
    if PATRON_COUNTER > PATRON_COUNTS[PATRON_PATTERN] and num_patrons <= MAX_PATRONS then
        PATRON_COUNTER = 0
        PATRON_PATTERN = love.math.random(#PATRON_COUNTS)
        local spawn_lane = love.math.random(#lanes)
        while spawn_lane == PATRON_SPAWNED_LAST do
            spawn_lane = love.math.random(#lanes) 
        end
        PATRON_SPAWNED_LAST = spawn_lane
        lanes[PATRON_SPAWNED_LAST]:spawnPatron()
    end
end

-- when a player moves down 
function love.keypressed(key, scancode, isrepeat) 
    if key == 'a' then
        -- move barkeep down
        MUGFILL_PERCENT = 0
        lanes[BARKEEP_INDEX].barkeep_here = false
        BARKEEP_INDEX = (BARKEEP_INDEX + 1) % (#lanes + 1)
        if BARKEEP_INDEX == 0 then
            BARKEEP_INDEX = 1
        end
        lanes[BARKEEP_INDEX].barkeep_here = true

    elseif key == 'd' then
        -- move barkeep up
        MUGFILL_PERCENT = 0
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

function resetGame() 
    SCORE = 0
    lanes = {
        Lane:new{y=200, barkeep_here=true},
        Lane:new{y=350},
        Lane:new{y=500},
        Lane:new{y=650}
    }
    MUGFILL_IN_PROGRESS = 0
    MUGFILL_IN_PROGRESS = false
end