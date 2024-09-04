-- GemItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/23/2024, 11:48:29 AM
--
---@type ns
local ns = select(2, ...)

---@class UI.GemItem : UI.SocketItem
local GemItem = ns.Addon:NewClass('UI.GemItem', ns.UI.SocketItem)

function GemItem:Constructor()
    self:SetScript('OnEnter', self.OnEnter)
    self:SetScript('OnLeave', GameTooltip_Hide)
    self:SetScript('OnHide', self.Free)
end

function GemItem:OnEnter()
    if self.item then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetHyperlink(self.item)
        GameTooltip:Show()
    end
end

function GemItem:SetItem(item)
    self.item = item
    self.Icon:SetTexture(GetItemIcon(item))
end

function GemItem:OnFree()
    self.item = nil
end

function GemItem:Alloc(parent)
    local obj = tremove(self.pool)
    if not obj then
        obj = self:New(parent)
    else
        obj:SetParent(parent)
    end
    obj:Show()
    return obj
end
