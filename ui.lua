--[[
ui.lua

Contains the UI for the menus
]]

local ui = {}
ui.draw = {}
ui.mouse = {}

local gfxopts = require 'gfxopts'

local images = {}

function ui.init(imageObj)
    images = imageObj
end

local function getTimer(time)
    local m = math.floor(time / 60)
    local s = math.floor(time - (m * 60))
    s = (s > 9 and s or "0" .. s)
    return m .. ":" .. s
end

local function getLongTimer(time)
    local h = math.floor(time / 3600)
    if h ~= 0 then
        return h .. ":" .. getTimer(time - (h * 3600))
    else
        return getTimer(time)
    end
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

function ui.draw.mainMenu(titleTimer)
    gfxopts.sColor(1,1,1,titleTimer / 5)
    gfxopts.gDraw(images.backgroundMenu, 0, 0, 0)
    gfxopts.gDraw(images.tetrislogo, 250, 50 * math.sin(math.pi * titleTimer * 0.1), 0, 0.2, 0.2)
    gfxopts.sColor((24/255),(211/255),(21/255),1)
    gfxopts.gRect("fill", 250, 300, 300, 50)
    gfxopts.sColor((153/255),0,1,1)
    gfxopts.gRect("fill", 250, 400, 300, 50)
    gfxopts.sColor(1,1,1,1)
    gfxopts.gPrint("Play", 375, 315)
    gfxopts.gPrint("Statistics", 325, 415)
end

function ui.mouse.mainMenu(uix, uiy, button, isTouch, titleTimer)
    local gamemode = 2
    --print(uix)
    local uix, uiy = love.window.fromPixels(uix), love.window.fromPixels(uiy)
    --print(uix)
    if (uix >= 250 and uix <= 550) and (uiy >= 300 and uiy <= 350) then
        gamemode = 3
        titleTimer = 5
    end
    if (uix >= 250 and uix <= 550) and (uiy >= 400 and uiy <= 450) then
        gamemode = 7
        titleTimer = 5
    end
    return gamemode, titleTimer
end

function ui.draw.gameSelect()
    gfxopts.gDraw(images.backgroundMenu, 0, 0)
    gfxopts.sColor(1,(153/255),0,1)
    gfxopts.gRect("fill", 250, 200, 300, 50)
    gfxopts.sColor(0,(190/255),0,1)
    gfxopts.gRect("fill", 250, 400, 300, 50)
    gfxopts.sColor(0.7,0,0.7,1)
    gfxopts.gRect("fill", 250, 600, 300, 50)
    gfxopts.sColor(1,1,1,1)
    gfxopts.gPrint("Marathon", 375, 215)
    gfxopts.gPrint("Sprint", 375, 415)
    gfxopts.gPrint("Ultra", 375, 615)
    gfxopts.gDraw(images.back, 5, 5, 0, 0.5, 0.5)
end

function ui.mouse.gameSelect(uix, uiy, button, isTouch)
    local gamemode = 3
    local subgame = 0
    local uix, uiy = love.window.fromPixels(uix), love.window.fromPixels(uiy)
    if (uix >= 5 and uix <= 50) and (uiy >= 5 and uiy <= 25) then
        gamemode = 2
    end
    if (uix >= 250 and uix <= 550) and (uiy >= 200 and uiy <= 250) then
        gamemode = 4
    end
    if (uix >= 250 and uix <= 550) and (uiy >= 400 and uiy <= 450) then
        gamemode = 4
        subgame = 1
    end
    if (uix >= 250 and uix <= 550) and (uiy >= 600 and uiy <= 650) then
        gamemode = 4
        subgame = 2
    end
    return gamemode, subgame
end

function ui.draw.levelSelect(level, subgame)
    gfxopts.gDraw(images.backgroundMenu, 0, 0)
    gfxopts.sColor(0,0,1,1)
    gfxopts.gRect("fill", 250, 500, 300, 50)
    if subgame == 0 then
        gfxopts.sColor(generateLevelColor(level))
        gfxopts.gRect("fill", 375, 325, 50, 50)
        gfxopts.sColor(1,1,1,1)
        gfxopts.gPrint(level, (level < 10 and 393 or 383), 335)
        gfxopts.gPrint("<", 350, 345)
        gfxopts.gPrint(">", 435, 345)
    else
        gfxopts.sColor(1,1,1,1)
    end
    gfxopts.gDraw(images.back, 5, 5, 0, 0.5, 0.5)
    gfxopts.gPrint("Play", 375, 515)
end

function ui.mouse.levelSelect(uix, uiy, button, isTouch, level)
    local gamemode = 4
    local countdown = 0
    local uix, uiy = love.window.fromPixels(uix), love.window.fromPixels(uiy)
    if (uix >= 5 and uix <= 50) and (uiy >= 5 and uiy <= 25) then
        gamemode = 3
    end
    if (uix >= 250 and uix <= 550) and (uiy >= 500 and uiy <= 550) then
        gamemode = 5
        countdown = 3
    end
    if (uix >= 345 and uix <= 365) and (uiy >= 340 and uiy <= 360) then
        level = level - 1
        if level == 0 then level = 1 end
    end
    if (uix >= 435 and uix <= 455) and (uiy >= 340 and uiy <= 360) then
        level = level + 1
        if level == 17 then level = 16 end
    end
    return gamemode, level, countdown
end

function ui.draw.stats(tstats, stats, subgame)
    gfxopts.gDraw(images.backgroundMenu, 0, 0)
    gfxopts.gDraw(images.back, 5, 5, 0, 0.5, 0.5)
    gfxopts.sColor(0.5,0.5,0.5,0.5)
    gfxopts.gRect("fill", 250, 90, 350, 500)
    gfxopts.sColor(1,1,1,1)
    love.graphics.setFont(bigFont)
    gfxopts.gPrint("Game Over", 320, 200)
    gfxopts.gPrint("High Score", 315, 450)
    love.graphics.setFont(font)
    if subgame == 0 then
        gfxopts.sColor(generateLevelColor(tstats.level))
        gfxopts.gRect("fill", 295, 295, 210, 30)
        gfxopts.sColor(1,1,1,1)
        gfxopts.gPrint("Level: " .. tstats.level, 300, 300)
    end
    gfxopts.gPrint("Score: " .. tstats.score, 300, 330)
    if subgame == 0 then
        gfxopts.gPrint("Time: " .. getTimer(tstats.time), 300, 360)
        gfxopts.gPrint("Lines: " .. tstats.lines, 300, 390)
    elseif subgame == 1 then
        gfxopts.gPrint("Time: " .. getTimer(tstats.time), 300, 360)
    elseif subgame == 2 then
        gfxopts.gPrint("Lines: " .. tstats.lines, 300, 360)
    end
    if subgame == 0 then
        gfxopts.gPrint(stats.marathon.score, 300, 500)
    elseif subgame == 1 then
        gfxopts.gPrint(stats.sprint.score, 300, 500)
    elseif subgame == 2 then
        gfxopts.gPrint(stats.ultra.score, 300, 500)
    end
end

function ui.mouse.stats(uix, uiy, button, isTouch)
    local gamemode = 6
    local uix, uiy = love.window.fromPixels(uix), love.window.fromPixels(uiy)
    if (uix >= 5 and uix <= 50) and (uiy >= 5 and uiy <= 25) then
        gamemode = 2
    end
    return gamemode
end

function ui.draw.paused()
    gfxopts.sColor(0.5,0.5,0.5,0.7)
    gfxopts.gRect("fill", 0, 0, 800, 700)
    gfxopts.sColor(0,(190/255),0,1)
    gfxopts.gRect("fill", 250, 400, 300, 50)
    gfxopts.sColor(0.9,0.1,0.1,1)
    gfxopts.gRect("fill", 250, 500, 300, 50)
    gfxopts.sColor(1,1,1,1)
    gfxopts.gPrint("Resume", 375, 415)
    gfxopts.gPrint("Quit", 375, 515)
    love.graphics.setFont(bigFont)
    gfxopts.gPrint("Paused", 300, 330)
    love.graphics.setFont(font)
end

function ui.mouse.paused(uix, uiy, button, isTouch)
    local gamemode = 5
    local paused = true
    local countdown = 0
    local uix, uiy = love.window.fromPixels(uix), love.window.fromPixels(uiy)
    if (uix >= 250 and uix <= 550) and (uiy >= 400 and uiy <= 450) then
        paused = false
        countdown = 3
    end
    if (uix >= 250 and uix <= 550) and (uiy >= 500 and uiy <= 550) then
        gamemode = 2
    end
    return gamemode, paused, countdown
end

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

function ui.draw.statsAllTime(stats)
    gfxopts.gDraw(images.backgroundMenu, 0, 0)
    gfxopts.gDraw(images.back, 5, 5, 0, 0.5, 0.5)
    gfxopts.sColor(0.5,0.5,0.5,0.5)
    gfxopts.gRect("fill", 250, 90, 350, 500)
    gfxopts.sColor(1,1,1,1)
    love.graphics.setFont(bigFont)
    gfxopts.gPrint("Statistics", 300, 100)
    love.graphics.setFont(font)
    gfxopts.gPrint("High Score: " .. stats.score, 275, 150)
    gfxopts.gPrint("Lines: " .. stats.lines, 275, 180)
    gfxopts.gPrint("Duration: " .. getLongTimer(stats.duration), 275, 210)
    gfxopts.gPrint("Awards:", 275, 240)
    for k=2,11 do
        gfxopts.gPrint(awardStrings[k] .. ": " .. stats.awardCounts[k], 300, 210 + (k * 30)) -- 210 = 270 - (2 * 30)
    end
end

function ui.mouse.statsAllTime(uix, uiy, button, isTouch)
    local gamemode = 7
    local uix, uiy = love.window.fromPixels(uix), love.window.fromPixels(uiy)
    if (uix >= 5 and uix <= 50) and (uiy >= 5 and uiy <= 25) then
        gamemode = 2
    end
    return gamemode
end

return ui