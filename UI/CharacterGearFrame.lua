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
    self:SetScript('OnHide', self.OnHide)

    self:SetUnit('player')
    self:UpdateName()
    self:UpdateClass()

    self.Talent2:SetScript('OnClick', function(button)
        if not InCombatLockdown() then
            SetActiveTalentGroup(button.id)
        end
    end)

    self.Portrait:SetScript('OnMouseUp', function()
        -- ns.Inspect:Query(nil, '出门带棍-范沃森')

        local menu = {}

        local characters = ns.Addon:GetCharacters()
        print('characters', characters)
        for _, character in ipairs(characters) do
            tinsert(menu, {
                text = character,
                func = function()
                    ns.Inspect:Query(nil, character, true)
                end,
            })
        end

        ns.CallMenu(self.Portrait, menu)
    end)
end

function CharacterGearFrame:OnShow()
    self:Event('UNIT_INVENTORY_CHANGED')
    self:Event('UNIT_LEVEL')
    self:Event('UNIT_MODEL_CHANGED')
    self:Event('PLAYER_TALENT_UPDATE', 'UpdateTalents')
    self:Event('ACTIVE_TALENT_GROUP_CHANGED', 'UpdateTalents')
    self:Event('PLAYER_AVG_ITEM_LEVEL_UPDATE', 'UpdateItemLevel')
    self:Event('TDINSPECT_OPTION_CHANGED', 'UpdateOption')

    self:UpdateOptionButton(ns.Addon.db.profile.showOptionButtonInCharacter)

    self:Update()

    if GearManagerDialog then
        GearManagerDialog:SetFrameLevel(self:GetFrameLevel() + 10)
    end
end

function CharacterGearFrame:OnHide()
    self:ResetColumnWidths()
    self:UnAllEvents()
    self:Hide()
    ns.Addon:OpenCharacterGearFrame()
end

function CharacterGearFrame:UNIT_LEVEL(_, unit)
    if unit == 'player' then
        self:UpdateLevel()
    end
end

function CharacterGearFrame:UNIT_INVENTORY_CHANGED(_, unit)
    if unit == 'player' then
        self:UpdateGears()
        self:UpdateItemLevel()
    end
end

function CharacterGearFrame:UNIT_MODEL_CHANGED(_, unit)
    if unit == 'player' then
        self:UpdatePortrait()
    end
end

function CharacterGearFrame:UpdateGears()
    self:ResetColumnWidths()

    for id, gear in pairs(self.gears) do
        gear:SetItem(GetInventoryItemLink('player', id))
    end
end

function CharacterGearFrame:UpdateItemLevel()
    local itemLevel = select(2, GetAverageItemLevel())
    if itemLevel <= 0 then
        if not self.itemLevelCalculator then
            self.itemLevelCalculator = ns.ItemLevelCalculator:New(function(slot)
                return GetInventoryItemLink('player', slot)
            end)
        end

        itemLevel = self.itemLevelCalculator:GetItemLevel()
    end
    self:SetItemLevel(itemLevel)
end

function CharacterGearFrame:UpdateLevel()
    self:SetLevel(UnitLevel('player'))
end

function CharacterGearFrame:Update()
    self:UpdatePortrait()
    self:UpdateLevel()
    self:UpdateGears()
    self:UpdateItemLevel()
    self:UpdateTalents()
end

function CharacterGearFrame:GetNumTalentGroups()
    return GetNumTalentGroups()
end

function CharacterGearFrame:GetActiveTalentGroup()
    return GetActiveTalentGroup()
end

function CharacterGearFrame:GetTalentInfo(group)
    local maxPoint = 0
    local maxName = nil
    local maxIcon
    local maxBg
    local counts = {}
    for i = 1, GetNumTalentTabs() do
        local name, icon, pointsSpent, bg = ns.GetTalentTabInfo(i, nil, nil, group)
        if pointsSpent > maxPoint then
            maxPoint = pointsSpent
            maxName = name
            maxIcon = icon
            maxBg = bg
        end

        tinsert(counts, pointsSpent)
    end
    return maxName, maxIcon, maxBg, table.concat(counts, '/')
end

function CharacterGearFrame:UpdateOption(_, key, value)
    if key == 'showTalentBackground' then
        if value then
            self:UpdateTalents()
        else
            self:SetBackground()
        end
    elseif key == 'showOptionButtonInCharacter' then
        self:UpdateOptionButton(value)
    elseif key == 'showGem' or key == 'showEnchant' or key == 'showLost' or key == 'showGemsFront' then
        self:UpdateGears()
    end
end
