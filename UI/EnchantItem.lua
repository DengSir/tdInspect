-- EnchantItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/23/2024, 12:00:23 PM
--
---@type ns
local ns = select(2, ...)

---@class UI.EnchantItem : UI.SocketItem
local EnchantItem = ns.Addon:NewClass('UI.EnchantItem', ns.UI.SocketItem)

function EnchantItem:Constructor()
    self:SetScript('OnEnter', self.OnEnter)
    self:SetScript('OnLeave', GameTooltip_Hide)
    self:SetScript('OnHide', self.Free)
end

function EnchantItem:OnFree()
    self.item = nil
    self.spell = nil
end

function EnchantItem:Alloc(parent)
    local obj = tremove(self.pool)
    if not obj then
        obj = self:New(parent)
    else
        obj:SetParent(parent)
    end
    obj:Show()
    return obj
end

function EnchantItem:OnEnter()
    if self.item then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetItemByID(self.item)
        GameTooltip:Show()
    elseif self.spell then
        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetSpellByID(self.spell)
        GameTooltip:Show()
    end
end

function EnchantItem:SetItem(item)
    self.item = item
    self.spell = nil
    self:Update()
end

function EnchantItem:SetSpell(spell)
    self.spell = spell
    self.item = nil
    self:Update()
end

function EnchantItem:Update()
    if self.item then
        self.Icon:SetTexture(GetItemIcon(self.item))
    elseif self.spell then
        self.Icon:SetTexture(select(3, GetSpellInfo(self.spell)))
    end
end
