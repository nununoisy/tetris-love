--[[
tetromino.lua

Contains functions for the Tetrimino Bag generator and draws Tetriminos
]]

local gfxopts = require 'gfxopts'

local floor = math.floor

local tetromino = {}
local defbag = {1,2,3,4,5,6,7}

-- 1:O, 2:I, 3:T, 4:L, 5:J, 6:S, 7:Z
-- 0:0, 1:R, 2:2, 3:L
-- mapped into 5x5 space
local tetriminoes = {
    {
        {0,0,12,12,0}, {0,0,12,12,0}, {0,0,12,12,0}, {0,0,12,12,0} -- O
    },
    {
        {0,4,4,4,4}, {0,0,15,0,0}, {4,4,4,4,0}, {0,0,30,0,0} -- I
    },
    {
        {0,4,12,4,0}, {0,0,14,4,0}, {0,4,6,4,0}, {0,4,14,0,0} -- T
    },
    {
        {0,4,4,12,0}, {0,0,14,2,0}, {0,6,4,4,0}, {0,8,14,0,0} -- L
    },
    {
        {0,12,4,4,0}, {0,0,14,8,0}, {0,4,4,6,0}, {0,2,14,0,0} -- J
    },
    {
        {0,4,12,8,0}, {0,0,12,6,0}, {0,2,6,4,0}, {0,12,6,0,0} -- S
    },
    {
        {0,8,12,4,0}, {0,0,6,12,0}, {0,4,6,2,0}, {0,6,12,0,0} -- Z
    }
}

local function shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = love.math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

local function TableConcat(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

function tetromino.bag(currentQueue)
    shufbag = shuffle(defbag)
    return TableConcat(currentQueue, shufbag)
end


--some sorcery from StackOverflow since Love uses Lua 5.1 which doesn't have bitwise

local function bitoper(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
      if a % 2 == 1 and b % 2 == 1 then -- test the rightmost bits
          result = result + bitval      -- set the current bit
      end
      bitval = bitval * 2 -- shift left
      a = floor(a/2) -- shift right
      b = floor(b/2)
    end
    return result
end

function tetromino.drawMino(shape, image, x, y, rot, fade)
    local tetriminoData = tetriminoes[shape][rot + 1] -- because Lua is 1-indexed, hooray!!
    for i=1,5 do
        for j=0,4 do
            local n = bitoper(tetriminoData[i], 2^j)
            if n ~= 0 then
                if fade == true then
                    gfxopts.sColor(1,1,1,1)
                    gfxopts.gRect("fill", (x + ((i-1) * 32)), (y + ((4-j) * 32)), 32, 32)
                else
                    gfxopts.gDraw(image, (x + ((i-1) * 32)), (y + ((4-j) * 32)), 0, 0.5, 0.5)
                end
            end
        end
    end
end

function tetromino.commitToGrid(shape, x, y, rot, grid)
    local tetriminoData = tetriminoes[shape][rot + 1] -- because Lua is 1-indexed, hooray!!
    for i=1,5 do
        for j=0,4 do
            local n = bitoper(tetriminoData[i], 2^j)
            if n ~= 0 then
                local dx = x + (i-3)
                local dy = y + (j-2)
                grid[dx][dy] = shape
            end
        end
    end
    return grid
end

function tetromino.canExistAs(shape, x, y, rot, grid)
    if not shape then return false end
    local tetriminoData = tetriminoes[shape][rot + 1] -- because Lua is 1-indexed, hooray!!
    for i=1,5 do
        for j=0,4 do
            local n = bitoper(tetriminoData[i], 2^j)
            if n ~= 0 then
                local dx = x + (i-3)
                local dy = y + (j-2)
                if dx <= 0 or dx > 10 or dy <= 0 or dy > 40 then
                    return false
                else
                    if grid[dx][dy] ~= 0 then
                        return false
                    end
                end
            end
        end
    end
    return true
end

function tetromino.getLowestValidPosition(shape, x, y, rot, grid)
    for j=y,1,-1 do
        if not tetromino.canExistAs(shape, x, j, rot, grid) then
            return j+1
        end
    end
    return 1
end

function tetromino.drawGhost(shape, image, gx, y, rot, grid)
    local gy = tetromino.getLowestValidPosition(shape, gx, y, rot, grid)
    if gy == y then return end
    local tetriminoData = tetriminoes[shape][rot + 1] -- because Lua is 1-indexed, hooray!!
    gfxopts.sColor(1,1,1,0.4)
    for i=1,5 do
        for j=0,4 do
            local n = bitoper(tetriminoData[i], 2^j)
            if n ~= 0 then
                gfxopts.gDraw(image, 102 + (32 * (gx + (i-1))), (32 * (25-gy-j)) - 66, 0, 0.5, 0.5)
            end
        end
    end
    gfxopts.sColor(1,1,1,1)
end

function tetromino.drawHardDropBlur(shape, image, x, y, rot, grid)
    local tetriminoData = tetriminoes[shape][rot + 1] -- because Lua is 1-indexed, hooray!!
    local iy = (y + tetromino.getLowestValidPosition(shape, x, y, rot, grid)) / 2
    for i=1,5 do
        for j=0,4 do
            local n = bitoper(tetriminoData[i], 2^j)
            if n ~= 0 then
                gfxopts.sColor(1,1,1,0.3)
                gfxopts.gDraw(image, 102 + (32 * (x + (i-1))), (32 * (25-y-j)) - 66, 0, 0.5, 0.5)
                gfxopts.sColor(1,1,1,0.6)
                gfxopts.gDraw(image, 102 + (32 * (x + (i-1))), (32 * (25-iy-j)) - 66, 0, 0.5, 0.5)
            end
        end
    end
    gfxopts.sColor(1,1,1,1)
end

otSpinA = {{-1,1},{1,1},{1,-1},{-1,-1}}
otSpinB = {{1,1},{1,-1},{-1,-1},{-1,1}}
otSpinC = {{-1,-1},{-1,1},{1,1},{1,-1}}
otSpinD = {{1,-1},{-1,-1},{-1,1},{1,1}}

function tetromino.tSpinCheck(shape, x, y, rot, grid, SRSpoint)
    -- 0: none, 1: T-Spin, 2: Mini T-Spin

    if shape ~= 3 then return 0 end

    local ptSpinA = otSpinA[rot + 1]
    local ptSpinB = otSpinB[rot + 1]
    local ptSpinC = otSpinC[rot + 1]
    local ptSpinD = otSpinD[rot + 1]
    
    local tSpinA = 1
    local tSpinB = 1
    local tSpinC = 1
    local tSpinD = 1

    if (x + ptSpinA[1]) >= 1 and (x + ptSpinA[1]) <= 10 and (y + ptSpinA[2]) >= 1 and (y + ptSpinA[2]) <= 40 then
        tSpinA = grid[x + ptSpinA[1]][y + ptSpinA[2]]
    end
    if (x + ptSpinB[1]) >= 1 and (x + ptSpinB[1]) <= 10 and (y + ptSpinB[2]) >= 1 and (y + ptSpinB[2]) <= 40 then
        tSpinB = grid[x + ptSpinB[1]][y + ptSpinB[2]]
    end
    if (x + ptSpinC[1]) >= 1 and (x + ptSpinC[1]) <= 10 and (y + ptSpinC[2]) >= 1 and (y + ptSpinC[2]) <= 40 then
        tSpinC = grid[x + ptSpinC[1]][y + ptSpinC[2]]
    end
    if (x + ptSpinD[1]) >= 1 and (x + ptSpinD[1]) <= 10 and (y + ptSpinD[2]) >= 1 and (y + ptSpinD[2]) <= 40 then
        tSpinD = grid[x + ptSpinD[1]][y + ptSpinD[2]]
    end

    local tSpinT = (tSpinA ~= 0 and 1 or 0) + (tSpinB ~= 0 and 1 or 0) + (tSpinC ~= 0 and 1 or 0) + (tSpinD ~= 0 and 1 or 0)

    if (tSpinA ~= 0 and tSpinB ~= 0) and (tSpinC ~= 0 or tSpinD ~= 0) then
        return 1
    end

    --[[
    if tSpinT >= 3 then
        return 1
    end
    --]]

    if (tSpinC ~= 0 and tSpinD ~= 0) and (tSpinA ~= 0 or tSpinB ~= 0) then
        if SRSpoint == 5 then
            return 1
        else
            return 2
        end
    end

    return 0
end

SRSoffsets = {
    {
        {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}},
        {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}},
        {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}},
        {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}}  -- O
    },
    {
        {{0,0}, {-1,0}, {2,0}, {-1,0}, {2,0}},
        {{-1,0}, {0,0}, {0,0}, {0,1}, {0,-2}},
        {{-1,1}, {1,1}, {-2,1}, {1,0}, {-2,0}},
        {{0,1}, {0,1}, {0,1}, {0,-1}, {0,2}}  -- I
    },
    {
        {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}},
        {{0,0}, {1,0}, {1,-1}, {0,2}, {1,2}},
        {{0,0}, {0,0}, {0,0}, {0,0}, {0,0}},
        {{0,0}, {-1,0}, {-1,-1}, {0,2}, {-1,2}}  -- T,L,J,S,Z
    }
}

function tetromino.attemptSRS(shape, x, y, rot, nrot, grid, willLock, attemptCount)
    local SRStableOffset = shape
    if shape > 2 then SRStableOffset = 3 end
    for d=1,5 do
        local SRSrot = SRSoffsets[SRStableOffset][rot + 1][d]
        local SRSnrot = SRSoffsets[SRStableOffset][nrot + 1][d]
        local SRSdx = SRSrot[1] - SRSnrot[1]
        local SRSdy = SRSrot[2] - SRSnrot[2]
        local tSpin = 0
        if tetromino.canExistAs(shape, x + SRSdx, y + SRSdy, nrot, grid) then
            if shape == 3 then
                tSpin = tetromino.tSpinCheck(shape, x + SRSdx, y + SRSdy, nrot, grid, d)
            else
                tSpin = 0
            end
            willLock = false
            print(attemptCount)
            if (y + SRSdy) == tetromino.getLowestValidPosition(shape, x + SRSdx, y + SRSdy, nrot, grid) or attemptCount < 15 then
                attemptCount = attemptCount - 1
                if attemptCount == 0 then
                    willLock = true
                end
            end
            return x + SRSdx, y + SRSdy, nrot, willLock, tSpin, attemptCount, true
        end
    end
    return x, y, rot, willLock, 0, attemptCount, false
end

function tetromino.clearLines(grid, lineCount)
    local nlineCount = lineCount
    for j=1,40 do
        local shouldRemove = true
        for i=1,10 do
            if grid[i][j] == 0 then
                shouldRemove = false
            end
        end
        if shouldRemove == true then
            nlineCount = nlineCount + 1
            for i=1,10 do
                for k=j,39 do
                    grid[i][k] = grid[i][k+1]
                end
                grid[i][40] = 0
            end
            return tetromino.clearLines(grid, nlineCount)
        end
    end
    return grid, lineCount
end

function tetromino.findLines(grid)
    local lineCount = 0
    local lineIndexes = {}
    for j=1,40 do
        local shouldRemove = true
        for i=1,10 do
            if grid[i][j] == 0 then
                shouldRemove = false
            end
        end
        if shouldRemove == true then
            lineCount = lineCount + 1
            table.insert(lineIndexes, j)
        end
    end
    return lineCount, lineIndexes
end

function tetromino.didAllClear(grid)
    local allClear = true
    for j=1,40 do
        local shouldRemove = true
        for i=1,10 do
            if grid[i][j] ~= 0 then
                allClear = false
            end
        end
    end
    return allClear
end

return tetromino