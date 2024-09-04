-- EquipItem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 11:26:46 AM
--
---@type ns
local ns = select(2, ...)

local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor

local GameTooltip = GameTooltip

local Inspect = ns.Inspect

---@class UI.EquipItem: UI.BaseItem
local EquipItem = ns.Addon:NewClass('UI.EquipItem', ns.UI.BaseItem)

function EquipItem:Constructor(_, id, slotName, hasBg)
    self:SetHeight(17)
    self:SetID(id)

    local Slot = self:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
    Slot:SetFont(Slot:GetFont(), 12, 'OUTLINE')
    Slot:SetWidth(38)
    Slot:SetPoint('LEFT')
    Slot:SetText(slotName)
    self.Slot = Slot

    local ItemLevel = self:CreateFontString(nil, 'ARTWORK', 'TextStatusBarText')
    ItemLevel:SetFont(ItemLevel:GetFont(), 13, 'OUTLINE')
    ItemLevel:SetJustifyH('LEFT')
    ItemLevel:SetPoint('LEFT', Slot, 'RIGHT', 5, 0)
    self.ItemLevel = ItemLevel

    local Name = self:CreateFontString(nil, 'ARTWORK', 'ChatFontNormal')
    Name:SetFont(Name:GetFont(), 13)
    Name:SetWordWrap(false)
    Name:SetJustifyH('LEFT')
    Name:SetPoint('LEFT', Slot, 'RIGHT', 30, 0)
    Name:SetPoint('RIGHT')
    self.Name = Name

    local Enchant = CreateFrame('Frame', nil, self)
    Enchant:SetPoint('TOPRIGHT')
    Enchant:SetHeight(17)
    Enchant:SetWidth(17)
    self.Enchant = Enchant

    local ht = self:CreateTexture(nil, 'HIGHLIGHT')
    ht:SetAllPoints(true)
    ht:SetColorTexture(0.5, 0.5, 0.5, 0.3)

    if hasBg then
        local bg = self:CreateTexture(nil, 'BACKGROUND')
        bg:SetAllPoints(true)
        bg:SetColorTexture(0.3, 0.3, 0.3, 0.3)
    end

    self:SetScript('OnLeave', GameTooltip_Hide)
    self:SetScript('OnEnter', self.OnEnter)
    self.UpdateTooltip = self.OnEnter

    self.enchantCount = 0
    self.enchants = {}
end

function EquipItem:AllocEnchant()
    self.enchantCount = self.enchantCount + 1

    for _, v in ipairs(self.enchants) do
        if not v:IsVisible() then
            v:Show()
            return v
        end
    end

    local Enchant = self.Enchant:CreateTexture(nil, 'ARTWORK')
    Enchant:SetSize(17, 17)
    if #self.enchants == 0 then
        Enchant:SetPoint('TOPRIGHT')
    else
        Enchant:SetPoint('TOPRIGHT', self.enchants[#self.enchants], 'TOPLEFT', 0, 0)
    end

    tinsert(self.enchants, Enchant)
    return Enchant
end

function EquipItem:FreeAllEnchants()
    self.enchantCount = 0
    for _, tex in ipairs(self.enchants) do
        tex.itemId = nil
        tex.spellId = nil
        tex:Hide()
    end
end

function EquipItem:OnHide()
    self:UnregisterAllEvents()
    self:FreeAllEnchants()
end

function EquipItem:OnEnter()
    local item = Inspect:GetItemLink(self:GetID())
    if item then

        for _, tex in ipairs(self.enchants) do
            if tex:IsVisible() and tex:IsMouseOver() then
                GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
                if tex.spellId then
                    GameTooltip:SetSpellByID(tex.spellId)
                else
                    GameTooltip:SetItemByID(tex.itemId)
                end
                return
            end
        end

        GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
        GameTooltip:SetHyperlink(item)
        ns.FixInspectItemTooltip(GameTooltip, self:GetID(), item)
    end
end

function EquipItem:Update()
    self:FreeAllEnchants()

    self.Name:SetText('')
    self.ItemLevel:SetText('')
    self.Slot:SetTextColor(0.6, 0.6, 0.6)

    local id = self:GetID()

    local item = Inspect:GetItemLink(id)
    if item then
        -- @build<2@
        local rune = Inspect:GetItemRune(id)
        if rune then
            local icon = rune.icon or select(3, GetSpellInfo(rune.spellId))
            local tex = self:AllocEnchant()
            tex.spellId = rune.spellId
            tex:SetTexture(icon)
        end
        -- @end-build<2@

        local enchantInfo = ns.GetItemEnchantInfo(item)
        if enchantInfo then
            local tex = self:AllocEnchant()
            if enchantInfo.itemId then
                tex.itemId = enchantInfo.itemId
                tex:SetTexture(GetItemIcon(enchantInfo.itemId))
            elseif enchantInfo.spellId then
                tex.spellId = enchantInfo.spellId
                tex:SetTexture(select(3, GetSpellInfo(enchantInfo.spellId)))
            end
        end

        for i = 1, 3 do
            local _, gemLink = GetItemGem(item, i)
            if gemLink then
                local tex = self:AllocEnchant()
                tex.itemId = ns.ItemLinkToId(gemLink)
                tex:SetTexture(GetItemIcon(gemLink))
            end
        end

        self.Enchant:SetWidth(max(0.1, 17 * self.enchantCount))
        self.Name:SetPoint('RIGHT', self.Enchant, 'LEFT', -2, 0)

        local name, link, quality, itemLevel = GetItemInfo(item)
        if name then
            local r, g, b = GetItemQualityColor(quality)

            self.itemId = nil
            self.Name:SetText(name)
            self.Name:SetTextColor(r, g, b)
            self.Slot:SetTextColor(r, g, b)
            self.ItemLevel:SetText(itemLevel)
            return
        else
            self:WaitItem(item)
            return
        end
    end
end
