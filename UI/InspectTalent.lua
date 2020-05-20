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
    self.initialOffsetX = 92
    self.initialOffsetY = 90
    self.Tabs = {}
    self.selectedTab = 1
    self.class = 'PALADIN'

    self:AddTab('Tab1')
    self:AddTab('Tab2')
    self:AddTab('Tab3')
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
        tab:SetPoint('TOPLEFT', 78, -41)
    else
        tab:SetPoint('LEFT', self.Tabs[id - 1], 'RIGHT')
    end

    self.Tabs[id] = tab

    PanelTemplates_TabResize(tab)
    PanelTemplates_SetNumTabs(self, id)
    PanelTemplates_UpdateTabs(self)
end

function InspectTalent:Update()
    TalentFrame.Update(self)

    for i = 1, 3 do
        local name = ns.Talent:GetTabInfo(self.class, i)
        self.Tabs[i]:SetText(name)
    end
end
