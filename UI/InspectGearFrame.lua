-- InspectGearFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 8/23/2024, 12:33:12 PM
--
---@type ns
local ns = select(2, ...)

local L = ns.L
local Inspect = ns.Inspect

---@class UI.InspectGearFrame : UI.GearFrame, Frame
local InspectGearFrame = ns.Addon:NewClass('UI.InspectGearFrame', ns.UI.GearFrame)

function InspectGearFrame:Constructor()
    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.OnHide)

    local DataSource = self:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
    DataSource:SetPoint('BOTTOMLEFT', self, 'TOPLEFT', 10, 0)
    DataSource:SetFont(DataSource:GetFont(), 12, 'OUTLINE')
    self.DataSource = DataSource
end

function InspectGearFrame:OnShow()
    self:RegisterMessage('INSPECT_READY', 'Update')
    self:RegisterEvent('UNIT_LEVEL', 'Update')
    self:RegisterEvent('UNIT_INVENTORY_CHANGED')
    self:Update()
end

function InspectGearFrame:OnHide()
    self.unit = nil
    self.class = nil
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
end

function InspectGearFrame:UNIT_INVENTORY_CHANGED(_, unit)
    if self.unit == unit then
        self:Update()
    end
end

function InspectGearFrame:Update()
    self:StartLayout()

    for id, gear in pairs(self.gears) do
        gear:SetItem(Inspect:GetItemLink(id), true)
    end

    local classFileName = Inspect:GetUnitClassFileName()
    local dataSource = Inspect:GetDataSource()
    local lastUpdate = Inspect:GetLastUpdate()

    self:SetClass(classFileName)
    self:SetUnit(Inspect:GetUnit())
    self:SetLevel(Inspect:GetUnitLevel())
    self:SetItemLevel(Inspect:GetItemLevel())
    self.DataSource:SetFormattedText('%s|cffffffff%s|r  %s|cffffffff%s|r', L['Data source:'], dataSource,
                                     L['Last update:'], FriendsFrame_GetLastOnline(lastUpdate))

    self:EndLayout()
end
