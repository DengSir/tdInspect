-- InspectFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 1:10:21 PM

---@type ns
local ns = select(2, ...)

local Inspect = ns.Inspect

local PlaySound = PlaySound
local Ambiguate = Ambiguate
local GetUnitName = GetUnitName
local SetPortraitTexture = SetPortraitTexture

---@type tdInspectInspectFrame
local InspectFrame = ns.Addon:NewClass('UI.InspectFrame', 'Frame')

function InspectFrame:Constructor()
    self:SuperCall('UnregisterAllEvents')
    self:SetScript('OnEvent', nil)

    self:SetScript('OnShow', self.OnShow)
    self:SetScript('OnHide', self.OnHide)

    self.tabFrames = {}
    for i, v in ipairs(INSPECTFRAME_SUBFRAMES) do
        self.tabFrames[i] = _G[v]
    end

    function InspectSwitchTabs(id)
        PanelTemplates_SetTab(self, id)

        for i, frame in ipairs(self.tabFrames) do
            frame:SetShown(i == id)
        end
    end

    self.Portrait = InspectFramePortrait
    self.Name = InspectNameText
    self.PaperDoll = ns.UI.PaperDoll:Bind(InspectPaperDollFrame)
    self.TalentFrame = ns.UI.InspectTalent:Bind(self:AddTab(TALENT))

    self.TalentFrame:Update()
end

function InspectFrame:OnShow()
    self:RegisterEvent('UNIT_NAME_UPDATE')
    self:RegisterEvent('UNIT_PORTRAIT_UPDATE')
    self:RegisterEvent('PORTRAITS_UPDATED', 'UpdatePortrait')
    self:RegisterMessage('INSPECT_TARGET_CHANGED', 'Update')
    self:Update()
    PlaySound(839) -- SOUNDKIT.IG_CHARACTER_INFO_OPEN
end

function InspectFrame:OnHide()
    self:UnregisterAllEvents()
    PlaySound(840) -- SOUNDKIT.IG_CHARACTER_INFO_CLOSE
    Inspect:Clear()
end

local function TabOnEnter(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    GameTooltip:SetText(self.text, 1.0, 1.0, 1.0)
end

function InspectFrame:AddTab(text)
    local id = self.numTabs + 1
    local tab = CreateFrame('Button', 'InspectFrameTab' .. id, self, 'CharacterFrameTabButtonTemplate')
    tab:SetPoint('LEFT', _G['InspectFrameTab' .. self.numTabs], 'RIGHT', -16, 0)
    tab:SetID(id)
    tab:SetText(text)
    tab:SetScript('OnClick', InspectFrameTab_OnClick)
    tab:SetScript('OnLeave', GameTooltip_Hide)
    tab:SetScript('OnEnter', TabOnEnter)
    tab.text = text
    PanelTemplates_SetNumTabs(self, 3)

    ---@type Frame
    local frame = CreateFrame('Frame', nil, self)
    frame:SetAllPoints(true)
    frame:Hide()

    local tl = frame:CreateTexture(nil, 'BACKGROUND')
    tl:SetSize(256, 256)
    tl:SetPoint('TOPLEFT', 2, -1)
    tl:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-TopLeft]])

    local tr = frame:CreateTexture(nil, 'BACKGROUND')
    tr:SetSize(128, 256)
    tr:SetPoint('TOPLEFT', 258, -1)
    tr:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-TopRight]])

    local bl = frame:CreateTexture(nil, 'BACKGROUND')
    bl:SetSize(256, 256)
    bl:SetPoint('TOPLEFT', 2, -257)
    bl:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-BottomLeft]])

    local br = frame:CreateTexture(nil, 'BACKGROUND')
    br:SetSize(128, 256)
    br:SetPoint('TOPLEFT', 258, -257)
    br:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-General-BottomRight]])

    self.tabFrames[id] = frame

    return frame
end

function InspectFrame:UpdatePortrait()
    if self.unit then
        SetPortraitTexture(self.Portrait, self.unit)
    else
        self.Portrait:SetTexture([[Interface\FriendsFrame\FriendsFrameScrollIcon]])
    end
end

function InspectFrame:UpdateName()
    if self.unit then
        self.Name:SetText(GetUnitName(self.unit))
    else
        self.Name:SetText(Ambiguate(Inspect.unitName, 'none'))
    end
end

function InspectFrame:Update()
    self:UpdatePortrait()
    self:UpdateName()
end

function InspectFrame:UNIT_NAME_UPDATE(_, unit)
    if unit == self.unit then
        self:UpdateName()
    end
end

function InspectFrame:UNIT_PORTRAIT_UPDATE(_, unit)
    if unit == self.unit then
        self:UpdatePortrait()
    end
end
