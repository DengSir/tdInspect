-- Menu.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/17/2020, 11:41:32 PM

---@type ns
local ns = select(2, ...)

local _G = _G
local select = select

local CloseDropDownMenus = CloseDropDownMenus
local UnitIsUnit = UnitIsUnit
local Ambiguate = Ambiguate
local CheckInteractDistance = CheckInteractDistance

local WHISPER = WHISPER
local BUTTON_HEIGHT = UIDROPDOWNMENU_BUTTON_HEIGHT

local FriendsDropDown = FriendsDropDown

UnitPopupButtons.INSPECT.dist = nil

local function GetDropdownUnitName()
    local menu = UIDROPDOWNMENU_INIT_MENU
    return menu and menu == FriendsDropDown and ns.GetFullName(menu.chatTarget)
end

---@type Button
local InspectButton = CreateFrame('Button', nil, UIParent)
do
    local ht = InspectButton:CreateTexture(nil, 'BACKGROUND')
    ht:SetAllPoints(true)
    ht:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
    ht:SetBlendMode('ADD')

    InspectButton:Hide()
    InspectButton:SetHeight(BUTTON_HEIGHT)
    InspectButton:SetHighlightTexture(ht)
    InspectButton:SetNormalFontObject('GameFontHighlightSmallLeft')
    InspectButton:SetText(INSPECT)

    InspectButton:SetScript('OnHide', InspectButton.Hide)
    InspectButton:SetScript('OnClick', function()
        local name = GetDropdownUnitName()
        if name then
            ns.Inspect:Query(nil, name)
        end
        CloseDropDownMenus()
    end)
    InspectButton:SetScript('OnEnter', function(self)
        local parent = self:GetParent()
        if parent then
            parent.isCounting = nil
        end
    end)
end

local function FindDropdownItem(dropdown, text)
    local name = dropdown:GetName()
    for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
        local dropdownItem = _G[name .. 'Button' .. i]
        if dropdownItem:IsShown() and dropdownItem:GetText() == text then
            return i, dropdownItem
        end
    end
end

local function FillToDropdownAfter(button, text, level)
    local dropdownName = 'DropDownList' .. level
    local dropdown = _G[dropdownName]
    local index, dropdownItem = FindDropdownItem(dropdown, WHISPER)
    if index then
        local x, y = select(4, dropdownItem:GetPoint())

        button:SetParent(dropdown)
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', x, y - BUTTON_HEIGHT)
        button:SetPoint('RIGHT', -x, 0)
        button:Show()

        for i = index + 1, UIDROPDOWNMENU_MAXBUTTONS do
            local dropdownItem = _G[dropdownName .. 'Button' .. i]
            if dropdownItem:IsShown() then
                local p, r, rp, x, y = dropdownItem:GetPoint(1)
                dropdownItem:SetPoint(p, r, rp, x, y - BUTTON_HEIGHT)
            else
                break
            end
        end

        dropdown:SetHeight(dropdown:GetHeight() + BUTTON_HEIGHT)
    end
end

hooksecurefunc('UnitPopup_ShowMenu', function(dropdownMenu, which, _, name)
    if which == 'FRIEND' and UIDROPDOWNMENU_MENU_LEVEL == 1 and not UnitIsUnit('player', Ambiguate(name, 'none')) then
        FillToDropdownAfter(InspectButton, WHISPER, 1)
    end
end)

function InspectUnit(unit)
    return ns.Inspect:Query(unit)
end
