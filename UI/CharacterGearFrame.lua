-- CharacterGearFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 9/4/2024, 4:30:30 PM
--
---@type ns
local ns = select(2, ...)

---@class UI.CharacterGearFrame : UI.GearFrame
local CharacterGearFrame = ns.Addon:NewClass('UI.CharacterGearFrame', ns.UI.GearFrame)

function CharacterGearFrame:Constructor()
    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.UnregisterAllEvents)
end

function CharacterGearFrame:OnShow()
    self:RegisterEvent('UNIT_INVENTORY_CHANGED')
    self:RegisterEvent('UNIT_LEVEL', 'UNIT_INVENTORY_CHANGED')
    self:Update()

    if GearManagerDialog then
        GearManagerDialog:SetFrameLevel(self:GetFrameLevel() + 10)
    end
end

function CharacterGearFrame:UNIT_INVENTORY_CHANGED(_, unit)
    if unit == 'player' then
        self:Update()
    end
end

function CharacterGearFrame:Update()
    self:StartLayout()

    self:SetUnit('player')
    self:SetClass(UnitClassBase('player'))
    self:SetLevel(UnitLevel('player'))
    self:SetItemLevel(select(2, GetAverageItemLevel()))

    for id, gear in pairs(self.gears) do
        gear:SetItem(GetInventoryItemLink('player', id), false)
    end

    self:EndLayout()
end
