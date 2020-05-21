-- InspectTalent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/20/2020, 1:37:49 PM

---@type ns
local ns = select(2, ...)

local TalentFrame = ns.UI.TalentFrame

---@type tdInspectInspectTalentFrame
local InspectTalent = ns.Addon:NewClass('UI.InspectTalent', TalentFrame)

function InspectTalent:Constructor()
    self.initialOffsetX = 86
    self.initialOffsetY = 90
    self.buttonSpacingX = 52
    self.buttonSpacingY = 48
    self.Tabs = {}
    self.selectedTab = 1

    self:AddTab('Tab1')
    self:AddTab('Tab2')
    self:AddTab('Tab3')

    self:SetScript('OnShow', self.OnShow)
end

local function TabOnClick(self)
    PanelTemplates_SetTab(self:GetParent(), self:GetID())
    self:GetParent():SetTalentTab(self:GetID())
end

function InspectTalent:AddTab(text)
    local id = #self.Tabs + 1
    local tab = CreateFrame('Button', nil, self, 'TabButtonTemplate')
    tab:SetID(id)
    tab:SetText(text)
    tab:SetScript('OnClick', TabOnClick)

    if id == 1 then
        tab:SetPoint('TOPLEFT', 70, -41)
    else
        tab:SetPoint('LEFT', self.Tabs[id - 1], 'RIGHT')
    end

    self.Tabs[id] = tab

    PanelTemplates_SetNumTabs(self, id)
    PanelTemplates_UpdateTabs(self)
end

function InspectTalent:OnShow()
    local class = ns.Inspect:GetUnitClass()
    local talent = ns.Inspect:GetUnitTalent()

    self:SetTalent(class, talent)

    for i = 1, 3 do
        local name = self.talent:GetTabInfo(i)
        if name then
            local tab = self.Tabs[i]
            tab:SetText(name)
            PanelTemplates_TabResize(tab, 0, nil, nil, 55)
        end
    end

    self:Refresh()
end
