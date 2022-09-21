-- GlyphFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2022/9/21 20:54:59
--
---@type ns
local ns = select(2, ...)

local GLYPH_SLOTS = {}
GLYPH_SLOTS[0] = {coords = {0.78125, 0.91015625, 0.69921875, 0.828125}}
GLYPH_SLOTS[1] = {coords = {0, 0.12890625, 0.87109375, 1}, points = {'CENTER', -15, 140}, glyphType = 1}
GLYPH_SLOTS[2] = {coords = {0.130859375, 0.259765625, 0.87109375, 1}, points = {'CENTER', -14, -103}, glyphType = 2}
GLYPH_SLOTS[3] = {coords = {0.392578125, 0.521484375, 0.87109375, 1}, points = {'TOPLEFT', 28, -133}, glyphType = 2}
GLYPH_SLOTS[4] = {coords = {0.5234375, 0.65234375, 0.87109375, 1}, points = {'BOTTOMRIGHT', -56, 168}, glyphType = 1}
GLYPH_SLOTS[5] = {coords = {0.26171875, 0.390625, 0.87109375, 1}, points = {'TOPRIGHT', -56, -133}, glyphType = 2}
GLYPH_SLOTS[6] = {coords = {0.654296875, 0.783203125, 0.87109375, 1}, points = {'BOTTOMLEFT', 26, 168}, glyphType = 1}

---@class UI.GlyphItem: Object, Button, AceEvent-3.0
local GlyphItem = ns.Addon:NewClass('UI.GlyphItem', 'Button')

function GlyphItem:Constructor(_, id)
    local slotData = GLYPH_SLOTS[id]
    self:SetSize(90, 90)
    self:SetPoint(unpack(slotData.points))

    local Setting = self:CreateTexture(nil, 'BACKGROUND')
    Setting:SetPoint('CENTER')
    Setting:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])

    local Highlight = self:CreateTexture(nil, 'BORDER')
    Highlight:SetPoint('CENTER')
    Highlight:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])
    Highlight:SetBlendMode('ADD')
    Highlight:SetAlpha(0.4)
    self:SetHighlightTexture(Highlight)

    local Background = self:CreateTexture(nil, 'BORDER')
    Background:SetPoint('CENTER')
    Background:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])
    Background:SetTexCoord(unpack(slotData.coords))

    local Ring = self:CreateTexture(nil, 'OVERLAY')
    -- Ring:SetPoint('CENTER')
    Ring:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])

    -- local Icon = self:CreateTexture(nil, 'ARTWORK')
    -- Icon:SetSize(53, 53)
    -- Icon:SetPoint('CENTER')
    -- Icon:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])

    if slotData.glyphType == 1 then
        Setting:SetSize(108, 108)
        Setting:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625)
        Highlight:SetSize(108, 108)
        Highlight:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625)
        Background:SetSize(70, 70)
        Ring:SetSize(82, 82);
        Ring:SetPoint('CENTER', self, 'CENTER', 0, -1);
        Ring:SetTexCoord(0.767578125, 0.92578125, 0.32421875, 0.482421875)
    else
        Setting:SetSize(86, 86)
        Setting:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
        Highlight:SetSize(86, 86)
        Highlight:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
        Background:SetSize(64, 64)
        Ring:SetSize(62, 62);
        Ring:SetPoint('CENTER', self, 'CENTER', 0, 1)
        Ring:SetTexCoord(0.787109375, 0.908203125, 0.033203125, 0.154296875)
    end

    self.Icon = Icon
end

---@class UI.GlyphFrame: Object, Frame, AceEvent-3.0
local GlyphFrame = ns.Addon:NewClass('UI.GlyphFrame', 'Frame')

function GlyphFrame:Constructor()
    local left, right, top, bottom = 16, 4, 35, 8

    local bg = self:CreateTexture(nil, 'BACKGROUND', nil, 1)
    bg:SetSize(352 - left - right, 441 - top - bottom)
    bg:SetPoint('TOPLEFT', left, -top)
    bg:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])
    bg:SetTexCoord(left / 512, 0.6875 - right / 512, top / 512, 0.861328125 - bottom / 512)

    for i = 1, 6 do
        GlyphItem:New(self, i)
    end

    self.bg = bg
end
