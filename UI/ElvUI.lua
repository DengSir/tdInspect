-- ElvUI.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 7/13/2021, 9:40:58 AM
--
if not ElvUI then
    return
end

---@type ns
local ns = select(2, ...)

local E = unpack(ElvUI)
local S = E:GetModule('Skins')

local function hook(t, m, f)
    local o = t[m]
    t[m] = function(...)
        return f(o, ...)
    end
end

hooksecurefunc(ns.Addon, 'SetupUI', function(self)
    self.InspectFrame.TalentFrame:StripTextures()
    self.InspectFrame.TalentFrame.TalentFrame:StripTextures()
    self.InspectFrame.TalentFrame.TalentFrame:CreateBackdrop('Default')

    self.InspectFrame.PaperDoll.ModelFrame:CreateBackdrop('Default')

    local i = #INSPECTFRAME_SUBFRAMES + 1
    while true do
        local tab = _G['InspectFrameTab' .. i]
        if not tab then
            break
        end
        S:HandleTab(tab)

        i = i + 1
    end

    for _, tab in ipairs(self.InspectFrame.TalentFrame.Tabs) do
        S:HandleTab(tab, true)
    end

    for _, tab in ipairs(self.InspectFrame.groupTabs) do
        tab:GetRegions():Hide()

        tab:SetTemplate()
        tab:StyleButton(nil, true)

        tab.nt:SetInside()
        tab.nt:SetTexCoord(unpack(E.TexCoords))

        tab.ct:SetInside()
        tab.ct:SetBlendMode('ADD')
        tab.ct:SetColorTexture(1, 1, 1, 0.3)
        tab.ct:SetTexCoord(unpack(E.TexCoords))
    end

    S:HandleScrollBar(self.InspectFrame.TalentFrame.TalentFrame.ScrollBar)
    -- S:HandleCheckBox(self.InspectFrame.PaperDoll.ToggleButton)

    self.InspectFrame.TalentFrame.Summary:GetParent():StripTextures()

    self.InspectFrame.GlyphFrame:StripTextures()

    local Background = self.InspectFrame.GlyphFrame.Background
    Background:Size(334, 385)
    Background:Point('TOPLEFT', 15, -47)
    Background:SetTexture([[Interface\Spellbook\UI-GlyphFrame]])
    Background:SetTexCoord(0.041015625, 0.65625, 0.140625, 0.8046875)

    InspectMainHandSlot:StripTextures()
    InspectSecondaryHandSlot:StripTextures()
    InspectRangedSlot:StripTextures()

    self.CharacterGearParent:SetPoint('TOPLEFT', CharacterFrame, 'TOPRIGHT', -30, -11)
end)

hooksecurefunc(ns.UI.SlotItem, 'UpdateBorder', function(self, r, g, b)
    if r then
        self.backdrop:SetBackdropBorderColor(r, g, b)
    else
        self.backdrop:SetBackdropBorderColor(unpack(E.media.bordercolor))
    end
    self.IconBorder:Hide()
end)

hook(ns.UI.TalentFrame, 'CreateTalentButton', function(orig, self, id)
    local button = orig(self, id)

    button:StripTextures()
    button:SetTemplate('Default')
    button:StyleButton()

    local icon = button.icon
    icon:SetInside()
    icon:SetTexCoord(unpack(E.TexCoords))
    icon:SetDrawLayer('ARTWORK')

    button.Rank:SetFont(E.LSM:Fetch('font', E.db['general'].font), 12, 'OUTLINE')

    return button
end)

ns.UI.GearFrame.BG_PADDING = 0

hooksecurefunc(ns.UI.GearFrame, 'Constructor', function(self)
    self:SetHeight(425)
    self:SetTemplate('Transparent')
    self.TopLeft:SetPoint('TOPLEFT', 0, 0)
end)

function ns.UI.GearFrame:TapTo(frame, position)
    self:SetParent(frame)
    self:ClearAllPoints()

    if position == 'TOPLEFT' then
        self:SetPoint('TOPLEFT', frame, 'TOPLEFT')
    elseif position == 'TOPRIGHT' then
        self:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 2, 0)
    end
end

do
    local orig = ns.Addon.GetInspectGearFrame

    function ns.Addon:GetInspectGearFrame()
        local f = orig(self)
        f:SetPoint('TOPLEFT', InspectPaperDollFrame, 'TOPRIGHT', -30, -11)
        ns.Addon.GetInspectGearFrame = orig
        return f
    end
end
