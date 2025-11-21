-- Modal.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 1:04:14 AM
--
---@type ns
local ns = select(2, ...)

local UnitFactionGroup = UnitFactionGroup

local Inspect = ns.Inspect

local factionLogoTextures = {
    Alliance = [[Interface\Timer\Alliance-Logo]],
    Horde = [[Interface\Timer\Horde-Logo]],
    Neutral = [[Interface\Timer\Panda-Logo]],
}

---@class UI.ModelFrame: EventHandler, Object, Frame
local ModelFrame = ns.Addon:NewClass('UI.ModelFrame', 'Frame')

function ModelFrame:Constructor()
    self.Modal = InspectModelFrame
    self.Faction = InspectFaction

    for _, region in ipairs({self.Modal:GetRegions()}) do
        region:SetParent(self)
    end
    self.Faction:SetPoint('CENTER')

    ---@type Texture
    local RaceBackground = self:CreateTexture(nil, 'ARTWORK')
    RaceBackground:SetAtlas('transmog-background-race-draenei')
    RaceBackground:SetAllPoints(self)

    self.Modal:SetParent(self)
    self.Faction:SetParent(self)
    self.RaceBackground = RaceBackground

    self:SetScript('OnShow', self.OnShow)
end

function ModelFrame:OnShow()
    self:Event('UNIT_MODEL_CHANGED', 'Update')
    self:Event('TDINSPECT_TARGET_CHANGED', 'Update')
    self:Update()
end

function ModelFrame:OnHide()
    self:UnAllEvents()
    self.modelName = nil
end

function ModelFrame:Update()
    local unit = Inspect.unit
    if unit then
        self.Modal:Show()

        if self.Modal:SetUnit(unit) then
            self.modelName = ns.UnitName(unit)
            self.Modal:Show()
            self.Faction:Hide()
            return
        end
    end

    if self.modelName == Inspect.unitName then
        return
    end

    self.modelName = nil
    self.Modal:Hide()
    self.Faction:SetTexture(factionLogoTextures[Inspect:GetUnitFactionGroup()])
    self.Faction:Show()
end
