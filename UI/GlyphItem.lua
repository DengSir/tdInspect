-- GlyphItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2022/9/23 16:21:24
--
---@type ns
local ns = select(2, ...)

local GLYPH_SLOTS = {
    [0] = {coords = {0.78125, 0.91015625, 0.69921875, 0.828125}},
    [1] = {coords = {0, 0.12890625, 0.87109375, 1}, points = {'CENTER', -15, 140}, glyphType = 1},
    [2] = {coords = {0.130859375, 0.259765625, 0.87109375, 1}, points = {'CENTER', -14, -103}, glyphType = 2},
    [3] = {coords = {0.392578125, 0.521484375, 0.87109375, 1}, points = {'TOPLEFT', 28, -133}, glyphType = 2},
    [4] = {coords = {0.5234375, 0.65234375, 0.87109375, 1}, points = {'BOTTOMRIGHT', -56, 168}, glyphType = 1},
    [5] = {coords = {0.26171875, 0.390625, 0.87109375, 1}, points = {'TOPRIGHT', -56, -133}, glyphType = 2},
    [6] = {coords = {0.654296875, 0.783203125, 0.87109375, 1}, points = {'BOTTOMLEFT', 26, 168}, glyphType = 1},
}

---@class UI.GlyphItem: Object, Button, AceEvent-3.0
local GlyphItem = ns.Addon:NewClass('UI.GlyphItem', 'Button')

function GlyphItem:Constructor(_, id)
    local slotData = GLYPH_SLOTS[id]
    self:SetSize(90, 90)
    self:SetPoint(unpack(slotData.points))

    local Setting = self:CreateTexture(nil, 'BACKGROUND')
    Setting:SetPoint('CENTER')

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
    Ring:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])

    local Icon = self:CreateTexture(nil, 'ARTWORK')
    Icon:SetSize(53, 53)
    Icon:SetPoint('CENTER')

    if slotData.glyphType == 1 then
        Highlight:SetSize(108, 108)
        Highlight:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625)
        Background:SetSize(70, 70)
        Ring:SetSize(82, 82);
        Ring:SetPoint('CENTER', self, 'CENTER', 0, -1);
        Ring:SetTexCoord(0.767578125, 0.92578125, 0.32421875, 0.482421875)
        Icon:SetVertexColor(1, 0.25, 0)
    else
        Highlight:SetSize(86, 86)
        Highlight:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
        Background:SetSize(64, 64)
        Ring:SetSize(62, 62);
        Ring:SetPoint('CENTER', self, 'CENTER', 0, 1)
        Ring:SetTexCoord(0.787109375, 0.908203125, 0.033203125, 0.154296875)
        Icon:SetVertexColor(0, 0.25, 1)
    end

    self:SetScript('OnEnter', self.OnEnter)
    self:SetScript('OnLeave', GameTooltip_Hide)

    self.id = id
    self.glyphType = slotData.glyphType
    self.Highlight = Highlight
    self.Setting = Setting
    self.Ring = Ring
    self.Background = Background
    self.Icon = Icon
end

function GlyphItem:OnEnter()
    if self.link or self.spellId then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        if self.link then
            GameTooltip:SetHyperlink(self.link)
        elseif self.spellId then
            GameTooltip:SetSpellByID(self.spellId)
        end
        GameTooltip:Show()
    end
end

function GlyphItem:UpdateInfo(enabled, icon, link, spellId)
    self.link = link
    self.spellId = spellId

    if not enabled then
        self.Background:Hide()
        self.Icon:Hide()
        self.Ring:Hide()
        self.Setting:SetTexture([[Interface\Spellbook\UI-GlyphFrame-Locked]])
        self.Setting:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        self.Setting:SetAlpha(0.6)
        self.Highlight:SetAlpha(0)
    else
        self.Icon:SetTexture(icon)
        self.Setting:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])
        self.Background:Show()
        self.Ring:Show()

        if not link and not spellId then
            self.Icon:Hide()
            self.Highlight:SetAlpha(0.4 * 0.6)
            self.Setting:SetAlpha(0.6)
            self.Background:SetAlpha(0.6)
            self.Background:SetTexCoord(unpack(GLYPH_SLOTS[0].coords))
        else
            self.Icon:Show()
            self.Highlight:SetAlpha(0.4)
            self.Setting:SetAlpha(1)
            self.Background:SetAlpha(1)
            self.Background:SetTexCoord(unpack(GLYPH_SLOTS[self.id].coords))
        end

        if self.glyphType == 1 then
            self.Setting:SetTexCoord(0.740234375, 0.953125, 0.484375, 0.697265625)
        else
            self.Setting:SetTexCoord(0.765625, 0.927734375, 0.15625, 0.31640625)
        end
    end

    if self.glyphType == 1 then
        self.Setting:SetSize(108, 108)
    else
        self.Setting:SetSize(86, 86)
    end
end
