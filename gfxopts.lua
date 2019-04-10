-- gfx-opts
-- Optimized/version agnostic graphics operations

local gfxopts = {}

local major, minor = love.getVersion()

function gfxopts.gDraw(drawable, x, y, r, sx, sy, ox, oy, kx, ky)
    local a, b, c = love.graphics.draw, love.window.toPixels, love.window.getDPIScale
    local r = r or 0    local sx = sx or 1
    local sy = sx or 1
    local ox = ox or 0
    local oy = ox or 0
    local kx = kx or 0
    local ky = ky or 0
    a(drawable, b(x), b(y), r, sx * c(), sy * c(), b(ox), b(oy), b(kx), b(ky))
end
--local sColor = love.graphics.setColor
function gfxopts.sColor(r,g,b,a)
    local aa = love.graphics.setColor
    if major >= 11 then
        aa(r,g,b,a)
    else
        aa(r*255,g*255,b*255,a)
    end
end

--local gRect = love.graphics.rectangle

function gfxopts.gRect(mode, x, y, width, height)
    local a, b = love.graphics.rectangle, love.window.toPixels
    a(mode, b(x), b(y), b(width), b(height))
end

-- local gPrint = love.graphics.print

function gfxopts.gPrint(text, x, y, r, sx, sy, ox, oy, kx, ky)
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

return gfxopts