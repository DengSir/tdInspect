-- CharacterGearFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 9/4/2024, 4:30:30 PM
--
---@type ns
local ns = select(2, ...)

---@class UI.CharacterGearFrame : UI.GearFrame
local CharacterGearFrame = ns.Addon:NewClass('UI.CharacterGearFrame', ns.UI.GearFrame)

local SetActiveTalentGroup = C_SpecializationInfo.SetActiveSpecGroup

local function SpecLeftClick(self)
    if InCombatLockdown() then
        return
    end
    if not self.isActive then
        SetActiveTalentGroup(self.id)
    else
        local equipmentSetId = ns.SpecGear:GetSpecGear(self.id)
        if equipmentSetId then
            local name = C_EquipmentSet.GetEquipmentSetInfo(equipmentSetId)
            if name then
                C_EquipmentSet.UseEquipmentSet(equipmentSetId)
            end
        end
    end
end

local function SpecOnClick(self, button)
    if button == 'LeftButton' then
        return SpecLeftClick(self)
    elseif button == 'RightButton' then
        return self:ToggleMenu()
    end
end

local function CreateMenu(self)
    local menu = {}
    tinsert(menu, {text = ns.L['Set Spec Equipment'], isTitle = true, notCheckable = true})

    for _, equipmentSetId in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local name = C_EquipmentSet.GetEquipmentSetInfo(equipmentSetId)
        tinsert(menu, {
            text = name,
            checked = ns.SpecGear:GetSpecGear(self.id) == equipmentSetId,
            func = function()
                ns.SpecGear:SetSpecGear(self.id, equipmentSetId)
            end,
        })
    end

    tinsert(menu, {
        text = ns.L['Clear Spec Equipment'],
        notCheckable = true,
        func = function()
            ns.SpecGear:SetSpecGear(self.id, nil)
        end,
    })

    tinsert(menu, ns.DROPDOWN_SEPARATOR)

    tinsert(menu, {
        text = ns.L['Set alias name'],
        notCheckable = true,
        func = function()
            if not StaticPopupDialogs['TDINSPECT_SET_SPEC_ALIAS'] then
                local function OnAccept(frame)
                    local editBox = frame.editBox or frame:GetEditBox()
                    local text = editBox:GetText()
                    ns.SpecGear:SetSpecAliasName(frame.data.specId, text)
                end

                StaticPopupDialogs['TDINSPECT_SET_SPEC_ALIAS'] = {
                    text = ns.L['Set alias name'],
                    button1 = ACCEPT,
                    button2 = CANCEL,
                    hasEditBox = true,
                    maxLetters = 20,
                    OnAccept = OnAccept,
                    EditBoxOnEnterPressed = function(self)
                        local parent = self:GetParent()
                        OnAccept(parent)
                        parent:Hide()
                    end,
                    OnShow = function(self)
                        local editBox = self.editBox or self:GetEditBox()
                        editBox:SetText(self.data.specName or '')
                        editBox:SetFocus()
                        editBox:HighlightText()
                    end,
                }
            end

            StaticPopup_Show('TDINSPECT_SET_SPEC_ALIAS', nil, nil,
                             {specId = self.id, specName = ns.SpecGear:GetSpecAliasName(self.id)})
        end,
    })
    return menu
end

function CharacterGearFrame:Constructor()
    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.OnHide)

    self:SetUnit('player')
    self:UpdateName()
    self:UpdateClass()

    ns.UI.MenuButton:Bind(self.Talent1, CreateMenu)
    ns.UI.MenuButton:Bind(self.Talent2, CreateMenu)

    self.Talent1:SetScript('OnClick', SpecOnClick)
    self.Talent2:SetScript('OnClick', SpecOnClick)
end

function CharacterGearFrame:OnShow()
    self:Event('UNIT_INVENTORY_CHANGED')
    self:Event('UNIT_LEVEL')
    self:Event('UNIT_MODEL_CHANGED')
    self:Event('PLAYER_TALENT_UPDATE', 'UpdateTalents')
    self:Event('ACTIVE_TALENT_GROUP_CHANGED', 'UpdateTalents')
    self:Event('PLAYER_AVG_ITEM_LEVEL_UPDATE', 'UpdateItemLevel')
    self:Event('TDINSPECT_OPTION_CHANGED', 'UpdateOption')
    self:Event('TDINSPECT_SPEC_ALIAS_CHANGED', 'UpdateTalents')

    self:UpdateOptionButton(ns.db.profile.showOptionButtonInCharacter)

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
    return ns.GetNumTalentGroups()
end

function CharacterGearFrame:GetActiveTalentGroup()
    return ns.GetActiveTalentGroup()
end

function CharacterGearFrame:GetTalentInfo(group)
    local maxPoint = 0
    local maxName
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

function CharacterGearFrame:GetSlotItem(id)
    return GetInventoryItemLink('player', id)
end
