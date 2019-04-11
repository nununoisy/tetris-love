--[[
    Gamemode states:
    -1: test
    0: Legal screen
    1: Load finished
    2: Title screen
    3: Game select
    4: Difficulty select
    5: Tetris
    6: Game over
    7: High-scores
]]
local loader
if (love._version_major == 0 and (love._version_minor < 9 or (love._version_minor == 9 and love._version_revision == 0))) or not love.getVersion then
    gamemode = -1
    love.getVersion = function()
        return (love._version_major or 0), (love._version_minor or 7), (love._version_revision or 0), ""
    end
    love.window = {}
    love.window.setMode = function(a,b)
    end
    love.window.setTitle = function(title)
    end
    love.joystick = {}
    love.joystick.getJoystickCount = function()
        return 0
    end
    loader = false
else
    -- desktop
    ---[[
    loader = require 'love-loader'
    --]]

    -- web
    --[[
    local loader = {}
    function loader.newImage(container, name, path)
        container[name] = love.graphics.newImage(path)
    end
    function loader.newSource(container, name, path)
        container[name] = love.audio.newSource(path, "static")
    end
    function loader.start(cb)
        cb()
    end
    function loader.update()
        loader.loadedCount = 1
    end
    loader.loadedCount = 0
    loader.resourceCount = 1
    --]]
end
local tetromino = require 'tetromino'
local ui = require 'ui'
local gfxopts = require 'gfxopts'

local profile = false

--local gDraw = love.graphics.draw

--[[
function love.window.toPixels(a)
    return a * 1.5
end

function love.window.fromPixels(a)
    return a / 1.5
end

function love.window.getDPIScale()
    return 1.5
end
--]]

local major, minor, revision, codename = love.getVersion()

if major < 11 then
    love.window.getDPIScale = function()
        return 1
    end
    love.filesystem.getInfo = love.filesystem.exists
end

local tDrawMino = tetromino.drawMino
local tDrawGhost = tetromino.drawGhost

local joystick = {}
local joystickExists = false

local saveChunk = nil
local gamemode = 0
local legalTimer = 3
local titleTimer = 0
local images = {}
local indexedMinos = {}
local indexedAwardGfx = {}
local sounds = {}
local s = nil
font = love.graphics.newFont("images/larabiefont.ttf", 20 * love.window.getDPIScale())
bigFont = love.graphics.newFont("images/larabiefont.ttf", 40 * love.window.getDPIScale())

local grid = {}
local queue = {}
local hold = 0
local level = 1

-- 1:O, 2:I, 3:T, 4:L, 5:J, 6:S, 7:Z
local curTetromino = 1
-- 0:0, 1:R, 2:2, 3:L
local curRotState = 0
local curPosX = 5
local curPosY = 1

-- Stats
stats = {}
local tstats = {}
-- Marathon
stats.marathon = {}
stats.marathon.score = 0
stats.marathon.level = 1
stats.marathon.lines = 0
stats.marathon.duration = 0
-- Sprint
stats.sprint = {}
stats.sprint.score = 0
stats.sprint.level = 1
stats.sprint.time = 0
stats.sprint.duration = 0
-- Ultra
stats.ultra = {}
stats.ultra.score = 0
stats.ultra.level = 1
stats.ultra.lines = 0
stats.ultra.duration = 0
-- Cumulative
stats.score = 0
stats.level = 1
stats.lines = 0
stats.duration = 0
stats.b2bCount = 0
stats.awardCounts = {0,0,0,0,0,0,0,0,0,0,0}

local function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

local function varToString(var)
	if type(var) == "string" then
		return "\"" .. var .. "\""
	elseif type(var) ~= "table" then
		return tostring(var)
	else
		local ret = "{ "
		local ts = {}
		local ti = {}
		for i, v in pairs(var) do
			if type(i) == "string" then
				table.insert(ts, i)
			else
				table.insert(ti, i)
			end
		end
		table.sort(ti)
		table.sort(ts)
		
		local comma = ""
		if #ti >= 1 then
			for i, v in ipairs(ti) do
				ret = ret .. comma .. varToString(var[v])
				comma = ", "
			end
		end
		
		if #ts >= 1 then
			for i, v in ipairs(ts) do
				ret = ret .. comma .. "[\"" .. v .. "\"] = " .. varToString(var[v])
				comma = ", "
			end
		end
		
		return ret .. "}"
	end
end

local function saveStats()
    love.filesystem.write("save.lua", "stats = " .. varToString(stats))
end

function love.load(arg)

    if not loader then return end

    love.window.setIcon(love.image.newImageData("images/tetris-love-logo.png"))

    if love.joystick.getJoystickCount() > 0 then
        joystick = love.joystick.getJoysticks()[1]
        joystickExists = true
    end

    if arg[1] == '--profiler' then 
        profile = true
        love.profiler = require('profile') 
        love.profiler.hookall("Lua")
        love.profiler.start()
    end

    love.filesystem.setIdentity("tetrislove")
    
    if love.filesystem.getInfo("save.lua") then
        
        love.filesystem.load("save.lua")()
        
    end
    love.window.setMode(800,700,{vsync=false, highdpi=true})
    love.window.setTitle("tetris-love")
    love.graphics.setFont(font)

    --image assets
    loader.newImage(images, 'tetrislogo', 'images/tetrislogo.png')
    loader.newImage(images, 'omino', 'images/newminos/omino.png')
    loader.newImage(images, 'imino', 'images/newminos/imino.png')
    loader.newImage(images, 'tmino', 'images/newminos/tmino.png')
    loader.newImage(images, 'lmino', 'images/newminos/lmino.png')
    loader.newImage(images, 'jmino', 'images/newminos/jmino.png')
    loader.newImage(images, 'smino', 'images/newminos/smino.png')
    loader.newImage(images, 'zmino', 'images/newminos/zmino.png')
    loader.newImage(images, 'awdouble', 'images/double.png')
    loader.newImage(images, 'awtriple', 'images/triple.png')
    loader.newImage(images, 'awtetris', 'images/tetrisAward.png')
    loader.newImage(images, 'awtspin', 'images/tspin.png')
    loader.newImage(images, 'awtspinSingle', 'images/tspinSingle.png')
    loader.newImage(images, 'awtspinDouble', 'images/tspinDouble.png')
    loader.newImage(images, 'awtspinTriple', 'images/tspinTriple.png')
    loader.newImage(images, 'awminiTspin', 'images/miniTspin.png')
    loader.newImage(images, 'awminiTspinSingle', 'images/miniTspinSingle.png')
    loader.newImage(images, 'back', 'images/back.png')
    loader.newImage(images, 'sparkles', 'images/sparkles.png')
    local pixelScale = (love.window.getDPIScale() > 2) and "@2x" or ""
    if pixelScale == "@2x" then
        font = love.graphics.newFont("images/larabiefont.ttf", 40)
        bigFont = love.graphics.newFont("images/larabiefont.ttf", 80)
    end
    
    loader.newImage(images, 'background', 'images/bg' .. pixelScale .. '.png')
    loader.newImage(images, 'backgroundMenu', 'images/bgOther' .. pixelScale .. '.png')

    -- sound assets
    loader.newSource(sounds, 'korobeiniki', 'sounds/lovekorobeiniki.wav')
    loader.newSource(sounds, 'lineclear', 'sounds/lineclear.wav')
    loader.newSource(sounds, 'lockdown', 'sounds/lockdown.wav')
    loader.newSource(sounds, 'levelup', 'sounds/levelup.wav')
    loader.newSource(sounds, 'rotate', 'sounds/rotate.wav')
    loader.newSource(sounds, 'tspin', 'sounds/tspin.wav')

    loader.start(function()
        indexedMinos = {
            images.omino,
            images.imino,
            images.tmino,
            images.lmino,
            images.jmino,
            images.smino,
            images.zmino
        }
        indexedAwardGfx = {
            nil,
            nil,
            images.awdouble,
            images.awtriple,
            images.awtetris,
            images.awminiTspin,
            images.awminiTspinSingle,
            images.awtspin,
            images.awtspinSingle,
            images.awtspinDouble,
            images.awtspinTriple
        }
        ui.init(images)
        gamemode = 1
    end)
    for i = 1, 10 do
        grid[i] = {}

        for j = 1, 40 do
            grid[i][j] = 0 -- Fill the values here
        end
    end
end

local slideTimer = 0
local slideSpeed = 0
local slideCounter = 0
local willGenerateTetromino = true
local willLock = false
local willHardDrop = false
local hardDropJsFlag = false
local oCurPosY = 0
local inFallingPhase = false
local timer = 0
local timerCeiling = 0
local lineCount = 0
local linesToClear = {}
local lineClearTimer = 1
local allClearFlag = false
local allClearTimer = 0
local linesToLevelUp = 5
local levelUp = 0
local holdAvailable = true
local tSpinFlag = 0
local SRSlockCounter = 15
local award = 1
local dAward = 0
local previousAward = 1
local backToBack = false
local awardTimer = 0
local score = 0
local softDrop = false
local gameOver = false
local isAnimating = false
local animLockFlag = false
local paused = false
local countdown = 0
local ddt = 0
local updateFrame = 0
-- 0: Marathon, 1: Sprint, 2: Ultra
local subGame = 0
local marathonLines = 0
local marathonTimer = 0
local sprintTimer = 0
local sprintLines = 0
local ultraLines = 0
local ultraTimer = 0

--[[
local awardStrings = {
    "",
    "Singles",
    "Doubles",
    "Triples",
    "Tetrises",
    "Mini T-Spins",
    "Mini T-Spin Singles",
    "T-Spins",
    "T-Spin Singles",
    "T-Spin Doubles",
    "T-Spin Triples"
}
--]]

local awards = {
    0,
    1,
    3,
    5,
    8,
    1,
    2,
    4,
    8,
    12,
    16
}

local awardVolumes = {
    0,
    0.2,
    0.4,
    0.6,
    0.8,
    0.3,
    0.4,
    0.6,
    0.7,
    0.8,
    1
}

local function genAward()
    if award > 1 then
        previousAward = award
    end
    if tSpinFlag == 0 then
        award = lineCount + 1
    elseif tSpinFlag == 1 then
        award = lineCount + 8
    else
        award = lineCount + 6
    end
    if award >= 5 and previousAward >= 5 then
        backToBack = true
        stats.b2bCount = stats.b2bCount + 1
    else
        backToBack = false
    end
    if award ~= 0 then
        dAward = award
        stats.awardCounts[award] = stats.awardCounts[award] + 1
        saveStats()
        awardTimer = 3
    end
end

local function getTimer(time)
    local m = math.floor(time / 60)
    s = math.floor(time - (m * 60))
    s = (s > 9 and s or "0" .. s)
    return m .. ":" .. s
end

local function hsvToRgb(h, s, v, a)
    local r, g, b
  
    local i = math.floor(h * 6);
    local f = h * 6 - i;
    local p = v * (1 - s);
    local q = v * (1 - f * s);
    local t = v * (1 - (1 - f) * s);
  
    i = i % 6
  
    if i == 0 then r, g, b = v, t, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
  
    return r, g, b, a
end

local function generateLevelColor(level)
    local hue = ((level - 1) % 15) / 15
    local value = 1 - ((math.floor(level / 15)) / 10)
    if value < 0.1 then value = 0.1 end
    return hsvToRgb(hue, 1, value, 1)
end

local function changeXPos(offset)
    if tetromino.canExistAs(curTetromino, curPosX + offset, curPosY, curRotState, grid) then
        curPosX = curPosX + offset
        tSpinFlag = 0
        willLock = false
    end
end

local function doMovement(dt)
    
    if love.keyboard.isDown("left") then
        if slideSpeed == 0 then
            changeXPos(-1)
            slideSpeed = 1
            slideTimer = 0.4
        end
        if slideTimer > 0 then
            slideTimer = slideTimer - dt
            if slideTimer <= 0 then slideTimer = 0 end
        else
            slideSpeed = slideSpeed + 1
            if slideSpeed > 3 then slideSpeed = 3 end
            slideTimer = 0.4
        end
        slideCounter = slideCounter + slideSpeed
        if slideCounter >= 60 then
            slideCounter = 0
            changeXPos(-1)
        end
    elseif love.keyboard.isDown("right") then
        if slideSpeed == 0 then
            changeXPos(1)
            slideSpeed = 1
            slideTimer = 0.4
        end
        if slideTimer > 0 then
            slideTimer = slideTimer - dt
            if slideTimer <= 0 then slideTimer = 0 end
        else
            slideSpeed = slideSpeed + 1
            if slideSpeed > 3 then slideSpeed = 3 end
            slideTimer = 0.4
        end
        slideCounter = slideCounter + slideSpeed
        if slideCounter >= 60 then
            slideCounter = 0
            changeXPos(1)
        end
    end
end

local function doMovementJS(dt)
    if joystick:getAxis(1) < -0.75 then
        if slideSpeed == 0 then
            changeXPos(-1)
            slideSpeed = 1
            slideTimer = 0.6
        end
        if slideTimer > 0 then
            slideTimer = slideTimer - dt
            if slideTimer <= 0 then slideTimer = 0 end
        else
            slideSpeed = slideSpeed + 1
            if slideSpeed > 3 then slideSpeed = 3 end
            slideTimer = 0.6
        end
        slideCounter = slideCounter + slideSpeed
        if slideCounter >= 78 then
            slideCounter = 0
            changeXPos(-1)
        end
    elseif joystick:getAxis(1) > 0.75 then
        if slideSpeed == 0 then
            changeXPos(1)
            slideSpeed = 1
            slideTimer = 0.6
        end
        if slideTimer > 0 then
            slideTimer = slideTimer - dt
            if slideTimer <= 0 then slideTimer = 0 end
        else
            slideSpeed = slideSpeed + 1
            if slideSpeed > 3 then slideSpeed = 3 end
            slideTimer = 0.6
        end
        slideCounter = slideCounter + slideSpeed
        if slideCounter >= 78 then
            slideCounter = 0
            changeXPos(1)
        end
    else
        slideSpeed = 0
        slideCounter = 0
    end
    if joystick:getAxis(2) < -0.75 then
        hardDropJsFlag = true
    else
        if hardDropJsFlag == true then
            hardDropJsFlag = false
            willHardDrop = true
            timerCeiling = 0
        end
    end
end

fCounter = 0

function love.update(dt)
    --[[fCounter = fCounter + 1
    if fCounter % 100 == 0 and profile then
        love.report = love.profiler.report('time', 20)
        love.profiler.reset()
        
        
    end
    --]]
    if gamemode == 0 then
        if loader then loader.update() end
    elseif gamemode == 1 then
        if sounds.korobeiniki:isPlaying() then
            sounds.korobeiniki:stop()
        end
        legalTimer = legalTimer - dt
        if legalTimer <= 0 then gamemode = 2 end
    elseif gamemode == 2 then
        if sounds.korobeiniki:isPlaying() then
            sounds.korobeiniki:stop()
        end
        titleTimer = titleTimer + dt
        if titleTimer >= 5 then titleTimer = 5 end
    elseif gamemode == 3 then
        titleTimer = 5
    elseif gamemode == 5 then
        if not sounds.korobeiniki:isPlaying() and not paused and countdown == 0 then
            sounds.korobeiniki:play()
        else
            if paused or countdown ~= 0 then sounds.korobeiniki:pause() end
        end
        if paused == false and countdown == 0 then
            timer = timer + dt
            if subGame == 0 then
                marathonTimer = marathonTimer + dt
            elseif subGame == 1 then
                sprintTimer = sprintTimer + dt
            elseif subGame == 2 then
                ultraTimer = ultraTimer - dt
                if ultraTimer <= 0 then
                    gameOver = true
                    gamemode = 6
                end
            end
        end
        if countdown > 0 then
            countdown = countdown - dt
            if countdown < 0 then countdown = 0 end
        end
        if awardTimer > 0 then
            awardTimer = awardTimer - dt
            if awardTimer < 0 then awardTimer = 0 end
        end
        if #linesToClear > 0 then
            lineClearTimer = lineClearTimer - (4 * dt)
            if lineClearTimer < 0 then 
                lineClearTimer = 1
                linesToClear = {}
                lineCount = 0
            end
            return
        end
        if allClearTimer > 0 then
            allClearTimer = allClearTimer - dt
            if allClearTimer < 0 then allClearTimer = 0 end
        end
        if joystickExists then
            doMovementJS(dt)
        else
            doMovement(dt)
        end
        softDrop = false
        local ntimerCeiling = timerCeiling
        if joystickExists then
            if joystick:getAxis(2) > 0.75 and inFallingPhase == true and willLock == false then
                ntimerCeiling = timerCeiling / 20
                softDrop = true
            end
        end
        if love.keyboard.isDown("down") and inFallingPhase == true and willLock == false and not joystickExists then
            ntimerCeiling = timerCeiling / 20
            softDrop = true
        end
        if timer >= ntimerCeiling and not paused then
            timer = 0

            -- BEGIN Generation Phase

            if #queue < 7 then
                queue = tetromino.bag(queue)
            end

            if levelUp > 0 then levelUp = levelUp - 1 end

            if willGenerateTetromino or curTetromino == 0 then
                grid, lineCount = tetromino.clearLines(grid, 0)
                score = score + (awards[award] * level * 100 * (backToBack == true and 1.5 or 1))
                if subGame == 0 then
                    linesToLevelUp = linesToLevelUp - math.floor(awards[award] * (backToBack == true and 1.5 or 1))
                    if linesToLevelUp <= 0 then
                        sounds.levelup:play()
                        level = level + 1
                        linesToLevelUp = (5 * level) + linesToLevelUp
                        levelUp = level * 3
                    end
                    marathonLines = marathonLines + math.floor(awards[award] * (backToBack == true and 1.5 or 1))
                elseif subGame == 1 then
                    sprintLines = sprintLines - math.floor(awards[award] * (backToBack == true and 1.5 or 1))
                    if sprintLines <= 0 then
                        gameOver = true
                        gamemode = 6
                    end
                elseif subGame == 2 then
                    ultraLines = ultraLines + math.floor(awards[award] * (backToBack == true and 1.5 or 1))
                end
                if tetromino.didAllClear(grid) and lineCount > 0 then
                    allClearTimer = 3
                    allClearFlag = false
                else
                    allClearFlag = true
                end
                linesToClear = {}
                willHardDrop = false
                holdAvailable = true
                tSpinFlag = 0
                timerCeiling = (0.8 - ((level - 1) * 0.007))^(level-1)
                animLockFlag = false
                curTetromino = table.remove(queue, 1)
                if (curPosY > 21 and holdAvailable == true) or not tetromino.canExistAs(curTetromino, 5, 21, 0, grid) then
                    gameOver = true
                    gamemode = 6
                end
                oCurPosY = 0
                SRSlockCounter = 15
                curRotState = 0
                curPosX = 5         -- As specified in the Guideline
                curPosY = 21
                willGenerateTetromino = false
                inFallingPhase = true
            end

            -- END Generation Phase
            -- BEGIN Falling Phase

            if willHardDrop then       -- Hard Drop?
                oCurPosY = curPosY
                curPosY = tetromino.getLowestValidPosition(curTetromino, curPosX, curPosY, curRotState, grid)
                oCurPosY = oCurPosY - curPosY
                score = score + (2*oCurPosY)
                tSpinFlag = 0
                s = sounds.lockdown:clone()
                s:play()
                grid = tetromino.commitToGrid(curTetromino, curPosX, curPosY, curRotState, grid)
                lineCount, linesToClear = tetromino.findLines(grid)
                genAward()
                if lineCount == 0 then 
                    animLockFlag = true
                else
                    sounds.lineclear:setVolume(awardVolumes[award])
                    sounds.lineclear:play()
                end
                --[[
                grid, lineCount = tetromino.clearLines(grid, 0)
                genAward()
                score = score + (awards[award] * level * 100 * (backToBack == true and 1.5 or 1))
                linesToLevelUp = linesToLevelUp - (awards[award] * (backToBack == true and 1.5 or 1))
                if linesToLevelUp <= 0 then
                    level = level + 1
                    linesToLevelUp = (5 * level) + linesToLevelUp
                end
                willHardDrop = false
                holdAvailable = true
                tSpinFlag = 0
                --]]
                willGenerateTetromino = true
                timerCeiling = (major >= 11) and 0.2 or 0.3
            else
                -- Lock Phase
                if willLock == false then
                    if tetromino.canExistAs(curTetromino, curPosX, curPosY - 1, curRotState, grid) then -- Space to Fall?
                        curPosY = curPosY - 1
                        if softDrop == true then score = score + 1 end
                        timerCeiling = (0.8 - ((level - 1) * 0.007))^(level-1)
                    else
                        willLock = true
                        inFallingPhase = false
                        timerCeiling = 0.5
                        return
                    end
                else
                    if curPosY ~= tetromino.getLowestValidPosition(curTetromino, curPosX, curPosY, curRotState, grid) and SRSlockCounter ~= 0 then
                        willLock = false
                        timerCeiling = (0.8 - ((level - 1) * 0.007))^(level-1)
                        return
                    end
                    grid = tetromino.commitToGrid(curTetromino, curPosX, curPosY, curRotState, grid)
                    sounds.lockdown:play()
                    lineCount, linesToClear = tetromino.findLines(grid)
                    genAward()
                    if lineCount == 0 then 
                        animLockFlag = true
                    else
                        sounds.lineclear:setVolume(awardVolumes[award])
                        sounds.lineclear:play()
                    end
                    --[[
                    grid, lineCount = tetromino.clearLines(grid, 0)
                    genAward()
                    score = score + (awards[award] * level * 100 * (backToBack == true and 1.5 or 1))
                    linesToLevelUp = linesToLevelUp - (awards[award] * (backToBack == true and 1.5 or 1))
                    if linesToLevelUp <= 0 then
                        level = level + 1
                        linesToLevelUp = 5 * level
                    end
                    --]]
                    willGenerateTetromino = true
                    -- holdAvailable = true
                    willLock = false
                    inFallingPhase = true
                    --tSpinFlag = 0
                    timerCeiling = (major >= 11) and 0.2 or 0.3
                end
            end
        end
    elseif gamemode == 6 then
        if sounds.korobeiniki:isPlaying() then
            sounds.korobeiniki:stop()
        end
    end
end

function love.mousereleased(uix, uiy, button, isTouch)
    if gamemode == 2 then
        gamemode = ui.mouse.mainMenu(uix, uiy, button, isTouch, titleTimer)
    elseif gamemode == 3 then
        level = 1
        gamemode, subGame = ui.mouse.gameSelect(uix, uiy, button, isTouch)
    elseif gamemode == 4 then
        gamemode, level, countdown = ui.mouse.levelSelect(uix, uiy, button, isTouch, level, subGame)
        if subGame == 0 then
            linesToLevelUp = level * 5
        elseif subGame == 1 then
            sprintLines = 40
            sprintTimer = 0
            level = 1
        elseif subGame == 2 then
            ultraTimer = 120
            ultraLines = 0
            level = 1
        end
        sounds.korobeiniki:stop()
        queue = {}
        hold = 0
        curTetromino = 1
        curRotState = 0
        curPosX = 5
        curPosY = 1
        willGenerateTetromino = true
        willLock = false
        willHardDrop = false
        inFallingPhase = false
        timer = 0
        timerCeiling = 0
        lineCount = 0
        linesToClear = {}
        lineClearTimer = 1
        allClearTimer = 0
        linesToLevelUp = 5
        levelUp = 0
        holdAvailable = true
        tSpinFlag = 0
        SRSlockCounter = 15
        award = 1
        dAward = 0
        previousAward = 1
        backToBack = false
        score = 0
        softDrop = false
        gameOver = false
        isAnimating = false
        animLockFlag = false
        paused = false
        for i = 1, 10 do
            grid[i] = {}
    
            for j = 1, 40 do
                grid[i][j] = 0 -- Fill the values here
            end
        end
    elseif gamemode == 5 and paused then
        gamemode, paused, countdown = ui.mouse.paused(uix, uiy, button, isTouch)
    elseif gamemode == 6 then
        gamemode = ui.mouse.stats(uix, uiy, button, isTouch)
    elseif gamemode == 7 then
        gamemode = ui.mouse.statsAllTime(uix, uiy, button, isTouch)
    end
end

local function changeRotState(offset)
    local didSRS = false
    local crs = curRotState + offset
    crs = (crs >= 0) and crs or 3
    crs = (crs <= 3) and crs or 0
    curPosX, curPosY, curRotState, willLock, tSpinFlag, SRSlockCounter, didSRS = tetromino.attemptSRS(curTetromino, curPosX, curPosY, curRotState, crs, grid, willLock, SRSlockCounter)
    return didSRS
end

local function hardDrop()
    willHardDrop = true
    timerCeiling = 0
end

local function useHold()
    if holdAvailable and not willGenerateTetromino then
        hold, curTetromino = curTetromino, hold
        curPosX, curPosY, curRotState = 5, 21, 0
        holdAvailable = false
        timerCeiling = 0
    end
end

local function togglePause()
    paused = not paused
    if not paused then countdown = 3 end
end

function love.keyreleased(key)
    local didSRS = false
    if gamemode == 5 and countdown == 0 and not joystickExists then
        if key == "left" and not paused then
            --changeXPos(-1)
            slideSpeed = 0
            slideCounter = 0
        elseif key == "right" and not paused then
            --changeXPos(1)
            slideSpeed = 0
            slideCounter = 0
        elseif (key == "up" or key == "x") and not paused then
            didSRS = changeRotState(1)
        elseif (key == "rctrl" or key == "lctrl" or key == "z") and not paused then
            didSRS = changeRotState(-1)
        elseif (key == "space" or key == " ") and not paused then
            hardDrop()
        elseif (key == "c" or key == "lshift" or key == "rshift") and not paused then
            useHold()
        elseif (key == "f1" or key == "escape") then
            togglePause()
        end
        if didSRS then
            if tSpinFlag ~= 0 then
                s = sounds.tspin:clone()
                s:play()
            else
                s = sounds.rotate:clone()
                s:play()
            end
        end
    end
end

function love.joystickreleased(joystick, button)
    local didSRS = false
    if gamemode == 5 and countdown == 0 then
        -- handled by axis 0
        if (button == 2 or button == 3) and not paused then
            didSRS = changeRotState(1)
        elseif (button == 4 or button == 1) and not paused then
            didSRS = changeRotState(-1)
        -- handled by axis 1
        elseif (button == 5 or button == 6) and not paused then
            useHold()
        elseif button == 10 then
            togglePause()
        end
        if didSRS then
            if tSpinFlag ~= 0 then
                s = sounds.tspin:clone()
                s:play()
            else
                s = sounds.rotate:clone()
                s:play()
            end
        end
    end
end

function love.draw()
    if gamemode == -1 then
        love.graphics.print("You are using an unsupported version of Love (".. (minor == 7 and "< 0.8.0" or  (major .. "." .. minor .. "." .. revision)) .. ").", 10, 10)
        love.graphics.print("Please update to at least 0.9.1.", 10, 30)
    elseif gamemode == 0 or gamemode == 1 then
        if not loader then
            gamemode = -1
            return
        end
        if legalTimer <= 0.5 then
            gfxopts.sColor(1,1,1,legalTimer * 2)  -- / 0.5
        end
        gfxopts.gPrint("Tetris ® and © 1985-2018 Tetris Holding.", 10, 10)
        gfxopts.gPrint("Tetris logos, Tetris theme song and Tetriminos are", 10, 35)
        gfxopts.gPrint("trademarks of Tetris Holding.", 10, 60)
        gfxopts.gPrint("The Tetris trade dress is owned by Tetris Holding.", 10, 85)
        gfxopts.gPrint("Licensed to the Tetris Company. Game design by Alexey Pajitnov.", 10, 110)
        gfxopts.gPrint("This game is not endorsed by or affiliated with the Tetris Company.", 10, 135)
        gfxopts.gPrint("tetris-love Game Code is © 2018 Noah Sweilem.", 10, 160)
        if major < 11 then
            gfxopts.gPrint("You are using Love " .. major .. "." .. minor .. "." .. revision .. " (" .. codename .. ").", 10, 300)
            gfxopts.gPrint("tetris-love works best on at least 11.0.0 (Mysterious Mysteries).", 10, 325)
        end
        if gamemode == 0 then
            --
            gfxopts.gPrint("Loading... " .. math.floor(loader.loadedCount / loader.resourceCount * 100) .. "%", 10, 190)
            gfxopts.gRect("line", 10, 220, 780, 50)
            gfxopts.gRect("fill", 15, 225, (770 * (loader.loadedCount / loader.resourceCount)), 40)
        else
            gfxopts.sColor(1,1,1,(legalTimer > 1.5 and (legalTimer - 1.5) / 1.5) or 0)
            gfxopts.gPrint("Done!", 10, 190)
            gfxopts.gRect("line", 10, 220, 780, 50)
            gfxopts.gRect("fill", 15, 225, 770, 40)
        end
        gfxopts.sColor(1,1,1,1)
    elseif gamemode == 2 then
        ui.draw.mainMenu(titleTimer)
    elseif gamemode == 3 then
        ui.draw.gameSelect()
    elseif gamemode == 4 then
        ui.draw.levelSelect(level, subGame)
    elseif gamemode == 5 then
        gfxopts.gDraw(images.background, 0, 0)
        if not paused and countdown == 0 then
            
            if curTetromino ~= 0 and not animLockFlag then
                tDrawMino(curTetromino, indexedMinos[curTetromino], (102 + (32 * curPosX)), ((32 * (20-curPosY)) - 34), curRotState, animLockFlag)
                if willGenerateTetromino == false then tDrawGhost(curTetromino, indexedMinos[curTetromino], curPosX, curPosY, curRotState, grid) end
            end

            for i = 1, 10 do
                for j = 1, 20 do
                    if grid[i][j] ~= 0 then
                        gfxopts.gDraw(indexedMinos[grid[i][j]], (198 + ((i - 1) * 32)), (((20 - j) * 32) + 30), 0, 0.5, 0.5)
                    end
                    if linesToClear ~= {} then
                        if contains(linesToClear, j) then
                            gfxopts.gRect("fill", 198, (((20 - j) * 32) + 30), (320 * math.sin((1 - lineClearTimer) * 0.5 * math.pi)), 32)
                            if lineCount == 4 then
                                gfxopts.gDraw(images.sparkles, (198 + (320 * math.sin((1 - lineClearTimer) * 0.5 * math.pi))), (((20 - j) * 32) + 30), 0, 0.5, 0.5)
                            end
                        end
                    end
                end
            end
            for i = 1, 5 do
                if queue[i] ~= nil then
                    tDrawMino(queue[i], indexedMinos[queue[i]], 560, (i * 96) - 44, 0, false)
                end
            end
            if hold ~= 0 then
                tDrawMino(hold, indexedMinos[hold], (hold ~= 2 and 20 or 10), 165, 0, false)
            end

            if oCurPosY ~= 0 then
                tetromino.drawHardDropBlur(curTetromino, indexedMinos[curTetromino], curPosX, oCurPosY + curPosY, curRotState, grid)
            end

            if animLockFlag == true then
                tDrawMino(curTetromino, indexedMinos[curTetromino], (102 + (32 * curPosX)), ((32 * (20-curPosY)) - 34), curRotState, animLockFlag)
            end
        end
        if indexedAwardGfx[dAward] ~= nil and awardTimer > 0 then
            gfxopts.gDraw(indexedAwardGfx[dAward], 0, 540, 0, 0.49, 0.49)
        end
        if allClearTimer > 0 then
            if allClearTimer < 1 then
                gfxopts.gRect("fill", 198 + (320 * math.sin((1 - allClearTimer) * 0.5 * math.pi)), 90, 320 - (320 * math.sin((1 - allClearTimer) * 0.5 * math.pi)), 50)
            elseif allClearTimer >= 1 and allClearTimer < 2 then
                gfxopts.gRect("fill", 198, 90, 320, 50)
                gfxopts.sColor(0,0,0,1)
                love.graphics.setFont(bigFont)
                gfxopts.gPrint("All Clear", 260, 95)
                love.graphics.setFont(font)
                gfxopts.sColor(1,1,1,1)
            else
                gfxopts.gRect("fill", 198, 90, (320 * math.sin((1 - (allClearTimer - 2)) * 0.5 * math.pi)), 50)
            end
        end
        gfxopts.gPrint("Score: " .. score, 5, 300)
        if subGame == 0 then
            gfxopts.sColor(generateLevelColor(level))
            gfxopts.gRect("fill", 3, 328, 150, 25)
            gfxopts.sColor(1,1,1,1)
            gfxopts.gPrint("Level " .. level, 5, 330)
            gfxopts.gPrint("Goal: " .. linesToLevelUp, 5, 360)
        elseif subGame == 1 then
            gfxopts.gPrint("Goal: " .. sprintLines, 5, 330)
            gfxopts.gPrint("Time: " .. getTimer(sprintTimer), 5, 360)
        elseif subGame == 2 then
            gfxopts.gPrint("Lines: " .. ultraLines, 5, 330)
            gfxopts.gPrint("Time: " .. getTimer(ultraTimer), 5, 360)
        end
        gfxopts.gPrint((backToBack == true and 'Back-to-Back ' or ''), 0, 510)
        if levelUp > 0 then
            love.graphics.setFont(bigFont)
            gfxopts.gPrint("Level Up", 300, 330)
            love.graphics.setFont(font)
        end
        if paused == true then
            ui.draw.paused()
        end
        if countdown > 0 then
            gfxopts.sColor(0.5,0.5,0.5,0.7)
            gfxopts.gRect("fill", 0, 0, 800, 700)
            local wave = math.sin(math.pi * (countdown - math.floor(countdown)))
            gfxopts.sColor(1,1,1,wave)
            love.graphics.setFont(bigFont)
            gfxopts.gPrint(math.ceil(countdown), 450 - (200 * (countdown - math.floor(countdown))), 330)
            love.graphics.setFont(font)
            gfxopts.sColor(1,1,1,1)
        end
    elseif gamemode == 6 then
        if gameOver then
            tstats.score = score
            if subGame == 0 then
                if score > stats.marathon.score then
                    stats.marathon.score = score
                    
                    saveStats()
                end
            elseif subGame == 1 then
                if score > stats.sprint.score then
                    stats.sprint.score = score
                    
                    saveStats()
                end
            elseif subGame == 2 then
                if score > stats.ultra.score then
                    stats.ultra.score = score
                    
                    saveStats()
                end
            end
            if score > stats.score then
                stats.score = score
                
                saveStats()
            end
            tstats.level = level
            if subGame == 0 then
                tstats.lines = marathonLines
                stats.lines = stats.lines + marathonLines
                tstats.time = marathonTimer
                stats.duration = stats.duration + marathonTimer
            elseif subGame == 1 then
                tstats.lines = sprintLines
                stats.lines = stats.lines + sprintLines
                tstats.time = sprintTimer
                stats.duration = stats.duration + sprintTimer
            elseif subGame == 2 then
                tstats.lines = ultraLines
                stats.lines = stats.lines + ultraLines
                tstats.time = ultraTimer
                stats.duration = stats.duration + ultraTimer
            end
            gameOver = false
        end
        ui.draw.stats(tstats, stats, subGame)
    elseif gamemode == 7 then
        ui.draw.statsAllTime(stats)
    end
end