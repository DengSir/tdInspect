-- SocketItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/23/2024, 5:40:57 PM
--
---@type ns
local ns = select(2, ...)

---@class UI.SocketItem : Button, AceEvent-3.0
local SocketItem = ns.Addon:NewClass('UI.SocketItem', 'Button')

SocketItem.pool = {}

local SIZE = 16
local ICON_SIZE = SIZE / 24 * 22
local BORDER_SIZE = SIZE / 24 * 33

function SocketItem:Inherit()
    self.pool = {}
end

function SocketItem:Constructor()
    self:SetSize(SIZE, SIZE)

    local Icon = self:CreateTexture(nil, 'ARTWORK')
    Icon:SetPoint('CENTER')
    Icon:SetSize(ICON_SIZE, ICON_SIZE)
    self.Icon = Icon

    local Border = self:CreateTexture(nil, 'OVERLAY')
    Border:SetPoint('CENTER')
    Border:SetAtlas('worldquest-tracker-ring')
    Border:SetSize(BORDER_SIZE, BORDER_SIZE)
    self.Border = Border

    local Mask = self:CreateMaskTexture()
    Mask:SetAllPoints(Icon)
    Mask:SetTexture([[Interface\CharacterFrame\TempPortraitAlphaMask]])
    Icon:AddMaskTexture(Mask)
end

function SocketItem:Free()
    self:Hide()
    self:OnFree()
    tinsert(self.pool, self)
end

function SocketItem:Alloc(parent)
    local obj = tremove(self.pool)
    if not obj then
        obj = self:New(parent)
    else
        obj:SetParent(parent)
    end
    obj:Show()
    return obj
end
