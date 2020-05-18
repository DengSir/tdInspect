-- PaperDoll.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 1:22:16 PM

---@type ns
local ns = select(2, ...)

local ipairs = ipairs
local pairs = pairs

local UnitLevel = UnitLevel
local UnitClass = UnitClass
local UnitRace = UnitRace
local GetClassColor = GetClassColor
local CreateFrame = CreateFrame

local PLAYER_LEVEL = PLAYER_LEVEL

local L = ns.L
local Inspect = ns.Inspect

---@type tdInspectPaperDoll
local PaperDoll = ns.Addon:NewClass('UI.PaperDoll', 'Frame')

function PaperDoll:Constructor()
    self:SuperCall('UnregisterAllEvents')
    self:SetScript('OnEvent', nil)

    self.buttons = {}

    for _, button in ipairs{
        InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot, InspectBackSlot, InspectChestSlot, InspectShirtSlot,
        InspectTabardSlot, InspectWristSlot, InspectHandsSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot,
        InspectFinger0Slot, InspectFinger1Slot, InspectTrinket0Slot, InspectTrinket1Slot, InspectMainHandSlot,
        InspectSecondaryHandSlot, InspectRangedSlot,
    } do
        self.buttons[button:GetID()] = ns.UI.SlotItem:Bind(button)
    end

    do
        local t1 = InspectMainHandSlot:CreateTexture(nil, 'BACKGROUND', 'Char-BottomSlot', -1)
        t1:ClearAllPoints()
        t1:SetPoint('TOPLEFT', -4, 8)

        local t2 = InspectMainHandSlot:CreateTexture(nil, 'BACKGROUND', 'Char-Slot-Bottom-Left')
        t2:ClearAllPoints()
        t2:SetPoint('TOPRIGHT', t1, 'TOPLEFT')

        local t3 = InspectSecondaryHandSlot:CreateTexture(nil, 'BACKGROUND', 'Char-BottomSlot', -1)
        t3:ClearAllPoints()
        t3:SetPoint('TOPLEFT', -4, 8)

        local t4 = InspectRangedSlot:CreateTexture(nil, 'BACKGROUND', 'Char-BottomSlot', -1)
        t4:ClearAllPoints()
        t4:SetPoint('TOPLEFT', -4, 8)

        local t5 = InspectRangedSlot:CreateTexture(nil, 'BACKGROUND', 'Char-Slot-Bottom-Right')
        t5:ClearAllPoints()
        t5:SetPoint('TOPLEFT', t4, 'TOPRIGHT')
    end

    ---@type CheckButton
    local ToggleButton = CreateFrame('CheckButton', nil, self)
    do
        ToggleButton:SetSize(20, 20)
        ToggleButton:SetPoint('BOTTOMLEFT', 23, 85)
        ToggleButton:SetNormalTexture([[Interface\Buttons\UI-CheckBox-Up]])
        ToggleButton:SetPushedTexture([[Interface\Buttons\UI-CheckBox-Down]])
        ToggleButton:SetCheckedTexture([[Interface\Buttons\UI-CheckBox-Check]])
        ToggleButton:SetHighlightTexture([[Interface\Buttons\UI-CheckBox-Highlight]], 'ADD')
        ToggleButton:SetFontString(ToggleButton:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall'))
        ToggleButton:GetFontString():SetPoint('LEFT', ToggleButton, 'RIGHT', 0, 0)
        ToggleButton:SetNormalFontObject('GameFontNormalSmall')
        ToggleButton:SetHighlightFontObject('GameFontHighlightSmall')
        ToggleButton:SetText(L['Show Modal'])

        ToggleButton:SetScript('OnClick', function()
            return self:UpdateInset()
        end)
    end

    ---@type Texture
    local RaceBackground = self:CreateTexture(nil, 'ARTWORK')
    do
        RaceBackground:SetPoint('TOPLEFT', 65, -76)
        RaceBackground:SetPoint('BOTTOMRIGHT', -85, 115)
        RaceBackground:SetAtlas('transmog-background-race-draenei')
        RaceBackground:SetDesaturated(true)
    end

    local LastUpdate = self:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmallLeft')
    do
        LastUpdate:SetPoint('BOTTOMLEFT', self, 'BOTTOMRIGHT', -130, 85)
    end

    self.RaceBackground = RaceBackground
    self.LastUpdate = LastUpdate
    self.ToggleButton = ToggleButton
    self.LevelText = InspectLevelText
    self.ModalFrame = ns.UI.ModalFrame:Bind(self:CreateInsetFrame())
    self.EquipFrame = ns.UI.EquipFrame:Bind(self:CreateInsetFrame())

    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.OnHide)
end

function PaperDoll:OnShow()
    self:RegisterMessage('INSPECT_READY', 'Update')
    self:RegisterEvent('UNIT_LEVEL', 'UpdateInfo')
    self:UpdateInfo()
    self:Update()
end

function PaperDoll:OnHide()
    self:UnregisterAllEvents()
    self:UnregisterAllMessages()
end

function PaperDoll:CreateInsetFrame()
    local frame = CreateFrame('Frame', nil, self)
    frame:SetPoint('TOPLEFT', 65, -76)
    frame:SetPoint('BOTTOMRIGHT', -85, 115)
    return frame
end

function PaperDoll:Update()
    for _, button in pairs(self.buttons) do
        button:Update()
    end
end

function PaperDoll:UpdateInfo()
    local unit = Inspect.unit
    if unit then
        local level = UnitLevel(unit)
        local class, classFileName = UnitClass(unit)
        local race, raceFileName = UnitRace(unit)

        class = ns.strcolor(class, GetClassColor(classFileName))

        self.LevelText:SetFormattedText(PLAYER_LEVEL, level, race, class)
        self.RaceBackground:SetAtlas('transmog-background-race-' .. raceFileName:lower())
        self.RaceBackground:Show()
    else
        self.LevelText:SetText('')
        self.RaceBackground:Hide()
    end

    local lastUpdate = Inspect:GetLastUpdate()
    if lastUpdate then
        self.LastUpdate:SetFormattedText('%s\n|cffffffff%s|r', L['Last update:'], FriendsFrame_GetLastOnline(lastUpdate))
    else
        self.LastUpdate:SetText('')
    end
end

function PaperDoll:UpdateInset()
    local checked = self.ToggleButton:GetChecked()
    self.ModalFrame:SetShown(checked)
    self.EquipFrame:SetShown(not checked)
end
