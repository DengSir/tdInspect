-- Glyph.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2022/9/23 10:43:41
--
---@class ns
local ns = select(2, ...)

---@class Glyph: Object
local Glyph = ns.Addon:NewClass('Glyph')

function Glyph:Constructor(data)
    self.data = data
end

function Glyph:GetGlyphSocketInfo(i)
    local socket = self.data and self.data[i]
    if not socket then
        return
    end
    return socket[1], socket[2], socket[3], socket[4]
end
