--[[
ui.lua

Contains the UI for the menus
]]

local ui = {}
ui.draw = {}
ui.mouse = {}

local function gDraw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    local a, b, c = love.graphics.draw, love.window.toPixels, love.window.getDPIScale
    local r = r or 0
    local sx = sx or 1
    local sy = sx or 1
    local ox = ox or 0
    local oy = ox or 0
    local kx = kx or 0
    local ky = ky or 0
    a(drawable, b(x), b(y), r, sx * c(), sy * c(), b(ox), b(oy), b(kx), b(ky))
end
local function sColor(r,g,b,a)
    local major = love.getVersion()
    local aa = love.graphics.setColor
    if major >= 11 then
        aa(r,g,b,a)
    else
        aa(r*255,g*255,b*255,a)
    end
end
local function gRect(mode, x, y, width, height)
    local a, b = love.graphics.rectangle, love.window.toPixels
    a(mode, b(x), b(y), b(width), b(height))
end
local function gPrint(text, x, y, r, sx, sy, ox, oy, kx, ky)
    local a, b, c = love.graphics.print, love.window.toPixels, love.window.getDPIScale
    local r = r or 0
    local sx = sx or 1
    local sy = sx or 1
    local ox = ox or 0
    local oy = ox or 0
    local kx = kx or 0
    local ky = ky or 0
    a(text, b(x), b(y), r, sx, sy, b(ox), b(oy), b(kx), b(ky))
end

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
    sColor(1,1,1,titleTimer / 5)
    gDraw(images.backgroundMenu, 0, 0, 0)
    gDraw(images.tetrislogo, 250, 50 * math.sin(math.pi * titleTimer * 0.1), 0, 0.2, 0.2)
    sColor((24/255),(211/255),(21/255),1)
    gRect("fill", 250, 300, 300, 50)
    sColor((153/255),0,1,1)
    gRect("fill", 250, 400, 300, 50)
    sColor(1,1,1,1)
    gPrint("Play", 375, 315)
    gPrint("Statistics", 325, 415)
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
    gDraw(images.backgroundMenu, 0, 0)
    sColor(1,(153/255),0,1)
    gRect("fill", 250, 200, 300, 50)
    sColor(0,(190/255),0,1)
    gRect("fill", 250, 400, 300, 50)
    sColor(0.7,0,0.7,1)
    gRect("fill", 250, 600, 300, 50)
    sColor(1,1,1,1)
    gPrint("Marathon", 375, 215)
    gPrint("Sprint", 375, 415)
    gPrint("Ultra", 375, 615)
    gDraw(images.back, 5, 5, 0, 0.5, 0.5)
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
    gDraw(images.backgroundMenu, 0, 0)
    sColor(0,0,1,1)
    gRect("fill", 250, 500, 300, 50)
    if subgame == 0 then
        sColor(generateLevelColor(level))
        gRect("fill", 375, 325, 50, 50)
        sColor(1,1,1,1)
        gPrint(level, (level < 10 and 393 or 383), 335)
        gPrint("<", 350, 345)
        gPrint(">", 435, 345)
    else
        sColor(1,1,1,1)
    end
    gDraw(images.back, 5, 5, 0, 0.5, 0.5)
    gPrint("Play", 375, 515)
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
    gDraw(images.backgroundMenu, 0, 0)
    gDraw(images.back, 5, 5, 0, 0.5, 0.5)
    sColor(0.5,0.5,0.5,0.5)
    gRect("fill", 250, 90, 350, 500)
    sColor(1,1,1,1)
    love.graphics.setFont(bigFont)
    gPrint("Game Over", 320, 200)
    gPrint("High Score", 315, 450)
    love.graphics.setFont(font)
    if subgame == 0 then
        sColor(generateLevelColor(tstats.level))
        gRect("fill", 295, 295, 210, 30)
        sColor(1,1,1,1)
        gPrint("Level: " .. tstats.level, 300, 300)
    end
    gPrint("Score: " .. tstats.score, 300, 330)
    if subgame == 0 then
        gPrint("Time: " .. getTimer(tstats.time), 300, 360)
        gPrint("Lines: " .. tstats.lines, 300, 390)
    elseif subgame == 1 then
        gPrint("Time: " .. getTimer(tstats.time), 300, 360)
    elseif subgame == 2 then
        gPrint("Lines: " .. tstats.lines, 300, 360)
    end
    if subgame == 0 then
        gPrint(stats.marathon.score, 300, 500)
    elseif subgame == 1 then
        gPrint(stats.sprint.score, 300, 500)
    elseif subgame == 2 then
        gPrint(stats.ultra.score, 300, 500)
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
    sColor(0.5,0.5,0.5,0.7)
    gRect("fill", 0, 0, 800, 700)
    sColor(0,(190/255),0,1)
    gRect("fill", 250, 400, 300, 50)
    sColor(0.9,0.1,0.1,1)
    gRect("fill", 250, 500, 300, 50)
    sColor(1,1,1,1)
    gPrint("Resume", 375, 415)
    gPrint("Quit", 375, 515)
    love.graphics.setFont(bigFont)
    gPrint("Paused", 300, 330)
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
    gDraw(images.backgroundMenu, 0, 0)
    gDraw(images.back, 5, 5, 0, 0.5, 0.5)
    sColor(0.5,0.5,0.5,0.5)
    gRect("fill", 250, 90, 350, 500)
    sColor(1,1,1,1)
    love.graphics.setFont(bigFont)
    gPrint("Statistics", 300, 100)
    love.graphics.setFont(font)
    gPrint("High Score: " .. stats.score, 275, 150)
    gPrint("Lines: " .. stats.lines, 275, 180)
    gPrint("Duration: " .. getLongTimer(stats.duration), 275, 210)
    gPrint("Awards:", 275, 240)
    for k=2,11 do
        gPrint(awardStrings[k] .. ": " .. stats.awardCounts[k], 300, 210 + (k * 30)) -- 210 = 270 - (2 * 30)
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