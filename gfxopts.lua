-- gfx-opts
-- Optimized/version agnostic graphics operations

local gfxopts = {}

local major, minor, revision, codename = love.getVersion()

local draw = love.graphics.draw
local color = love.graphics.setColor
local rect = love.graphics.rectangle
local tpix = love.graphics.toPixels or function(a) return a end
local fpix = love.graphics.fromPixels or function(a) return a end
local dpi = love.graphics.getDPIScale or function() return 1 end
local gfprt = love.graphics.print

function gfxopts.gDraw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    local r = r or 0
    local sx = sx or 1
    local sy = sx or 1
    local ox = ox or 0
    local oy = ox or 0
    local kx = kx or 0
    local ky = ky or 0
    draw(drawable, tpix(x), tpix(y), r, sx * dpi(), sy * dpi(), tpix(ox), tpix(oy), tpix(kx), tpix(ky))
end
--local sColor = love.graphics.setColor
function gfxopts.sColor(r,g,b,a)
    if major >= 11 then
        color(r,g,b,a)
    else
        color(r*255,g*255,b*255,a*255)
    end
end

--local gRect = love.graphics.rectangle

function gfxopts.gRect(mode, x, y, width, height)
    rect(mode, tpix(x), tpix(y), tpix(width), tpix(height))
end

-- local gPrint = love.graphics.print

function gfxopts.gPrint(text, x, y, r, sx, sy, ox, oy, kx, ky)
    local r = r or 0
    local sx = sx or 1
    local sy = sx or 1
    local ox = ox or 0
    local oy = ox or 0
    local kx = kx or 0
    local ky = ky or 0
    gfprt(text, tpix(x), tpix(y), r, sx, sy, tpix(ox), tpix(oy), tpix(kx), tpix(ky))
end

return gfxopts