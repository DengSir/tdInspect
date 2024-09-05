-- TipScaner.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/22/2020, 9:31:04 AM
---@class ns
local ns = select(2, ...)

---@class TipScaner : GameTooltip
local TipScaner = CreateFrame('GameTooltip')
ns.TipScaner = TipScaner

---@type FontString[]
local LFonts, RFonts = {}, {}

for i = 1, 40 do
    LFonts[i], RFonts[i] = TipScaner:CreateFontString(), TipScaner:CreateFontString()
    LFonts[i]:SetFontObject('GameFontNormal')
    RFonts[i]:SetFontObject('GameFontNormal')
    TipScaner:AddFontStrings(LFonts[i], RFonts[i])
end

function TipScaner:Clear()
    self:ClearLines()
    if not self:IsOwned(WorldFrame) then
        self:SetOwner(WorldFrame, 'ANCHOR_NONE')
    end
end

TipScaner.L = LFonts
TipScaner.R = RFonts
