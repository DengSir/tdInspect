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

    self.Portrait = InspectFramePortrait
    self.Name = InspectNameText
    self.PaperDoll = ns.UI.PaperDoll:Bind(InspectPaperDollFrame)
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
