-- InspectTalent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/20/2020, 1:37:49 PM

---@type ns
local ns = select(2, ...)

local Inspect = ns.Inspect

local CreateFrame = CreateFrame

local PanelTemplates_SetTab = PanelTemplates_SetTab
local PanelTemplates_SetNumTabs = PanelTemplates_SetNumTabs
local PanelTemplates_UpdateTabs = PanelTemplates_UpdateTabs
local PanelTemplates_TabResize = PanelTemplates_TabResize

---@type tdInspectInspectTalentFrame
local InspectTalent = ns.Addon:NewClass('UI.InspectTalent', 'Frame')

function InspectTalent:Constructor()
    self.Tabs = {}
    self.selectedTab = 1

    self:AddTab('Tab1')
    self:AddTab('Tab2')
    self:AddTab('Tab3')

    local TalentFrame = ns.UI.TalentFrame:New(self)
    TalentFrame:SetPoint('TOPLEFT', 23, -77)
    TalentFrame:SetSize(320, 353)
    TalentFrame.initialOffsetX = 65
    TalentFrame.initialOffsetY = 13

    self.TalentFrame = TalentFrame

    self:SetScript('OnShow', self.OnShow)
end

function InspectTalent:OnShow()
    self:RegisterMessage('INSPECT_TALENT_READY', 'UpdateInfo')
    self:UpdateInfo()
end

local function TabOnClick(self)
    self:GetParent():SetTab(self:GetID())
end

function InspectTalent:AddTab(text)
    local id = #self.Tabs + 1
    local tab = CreateFrame('Button', nil, self, 'TabButtonTemplate', id)
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

function InspectTalent:SetTab(id)
    PanelTemplates_SetTab(self, id)
    self.TalentFrame:SetTalentTab(id)
end

function InspectTalent:UpdateInfo()
    local class = Inspect:GetUnitClassFileName()
    local talent = Inspect:GetUnitTalent()

    print(class, talent)

    self.TalentFrame:SetTalent(class, talent)

    for i = 1, GetNumTalentTabs() do
        local name = self.TalentFrame.talent:GetTabInfo(i)
        if name then
            local tab = self.Tabs[i]
            tab:SetText(name)
            PanelTemplates_TabResize(tab, 0, nil, nil, 55)
        end
    end
end
