-- PaperDoll.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 1:22:16 PM
--
---@type ns
local ns = select(2, ...)

local ipairs = ipairs
local pairs = pairs

local UnitLevel = UnitLevel
local UnitClass = UnitClass
local UnitRace = UnitRace
local GetClassColor = GetClassColor
local CreateFrame = CreateFrame

local PLAYER_LEVEL = PLAYER_LEVEL:gsub('%%d', '%%s')

local L = ns.L
local Inspect = ns.Inspect

---@class UI.PaperDoll: EventHandler, Object, Frame
local PaperDoll = ns.Addon:NewClass('UI.PaperDoll', 'Frame')

function PaperDoll:Constructor()
    self:UnregisterAllEvents()
    self:SetScript('OnEvent', nil)
    self.RegisterEvent = nop

    self.buttons = {}

    for _, button in ipairs {
        InspectHeadSlot, InspectNeckSlot, InspectShoulderSlot, InspectBackSlot, InspectChestSlot, InspectShirtSlot,
        InspectTabardSlot, InspectWristSlot, InspectHandsSlot, InspectWaistSlot, InspectLegsSlot, InspectFeetSlot,
        InspectFinger0Slot, InspectFinger1Slot, InspectTrinket0Slot, InspectTrinket1Slot, InspectMainHandSlot,
        InspectSecondaryHandSlot, InspectRangedSlot,
    } do
        self.buttons[button:GetID()] = ns.UI.SlotItem:Bind(button)
    end

    self.LevelText = InspectLevelText
    self.ModelFrame = ns.UI.ModelFrame:Bind(self:CreateInsetFrame())

    self.RaceBackground = self.ModelFrame.RaceBackground

    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.OnHide)
end

function PaperDoll:OnShow()
    self:Event('TDINSPECT_READY', 'UpdateAll')
    self:Event('UNIT_LEVEL', 'UpdateInfo')
    self:Event('TDINSPECT_OPTION_CHANGED')
    self:UpdateInfo()
    self:Update()
    ns.Addon:OpenInspectGearFrame()
end

function PaperDoll:OnHide()
    self:UnAllEvents()
end

function PaperDoll:TDINSPECT_OPTION_CHANGED(_, key)
    if key == 'itemLevelColor' then
        self:Update()
    end
end

function PaperDoll:UpdateAll()
    self:Update()
    self:UpdateInfo()
end

function PaperDoll:CreateInsetFrame()
    local frame = CreateFrame('Frame', nil, self)
    frame:SetAllPoints(InspectModelFrame)
    return frame
end

function PaperDoll:Update()
    for _, button in pairs(self.buttons) do
        button:Update()
    end
end

function PaperDoll:UpdateInfo()
    local level = Inspect:GetUnitLevel()
    local class = Inspect:GetUnitClass()
    local race = Inspect:GetUnitRace()
    local classFileName = Inspect:GetUnitClassFileName()
    local raceFileName = Inspect:GetUnitRaceFileName()
    local lastUpdate = Inspect:GetLastUpdate()

    self.LevelText:SetFormattedText(PLAYER_LEVEL, level or '??', race or '',
                                    class and ns.strcolor(class, GetClassColor(classFileName)) or '')

    if raceFileName then
        if raceFileName == 'Scourge' then
            raceFileName = 'Undead'
        end
        self.RaceBackground:SetAtlas('transmog-background-race-' .. raceFileName)
    else
        self.RaceBackground:SetAtlas(UnitFactionGroup('player') == 'Alliance' and 'transmog-background-race-draenei' or
                                         'transmog-background-race-bloodelf')
    end
end
