-- MistsTalentFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2024/1/1
--
---@type ns
local ns = select(2, ...)

if ns.BUILD < 5 then
    return
end

local GameTooltip = GameTooltip
local CreateFrame = CreateFrame
local GetSpellInfo = GetSpellInfo
local SetDesaturation = SetDesaturation

-- Textures matching Blizzard's PlayerTalentButtonTemplate / PlayerTalentRowTemplate
local TALENT_MAIN  = [[Interface\TalentFrame\talent-main]]
local TALENT_HORIZ = [[Interface\TalentFrame\talent-horiz]]
local TALENT_SLOT  = [[Interface\Buttons\UI-EmptySlot-Disabled]]

-- TexCoords from PlayerTalentButtonTemplate
local TC_SEL  = {0.00390625, 0.74609375, 0.37304688, 0.47265625} -- knownSelection (ADD)
local TC_HL   = {0.00390625, 0.78515625, 0.25000000, 0.36914063} -- hover highlight (ADD)
local TC_LCAP = {0.140625,   0.26953125, 0.47656250, 0.58593750} -- row left cap
local TC_RCAP = {0.00390625, 0.140625,   0.47656250, 0.58593750} -- row right cap

local BTN_H    = 40
local ROW_GAP  = 4
local ICON_SIZE = 34
local CAP_W    = 13
local START_Y  = -4

---@class UI.MistsTalentFrame: Object, Frame
local MistsTalentFrame = ns.Addon:NewClass('UI.MistsTalentFrame', 'Frame')

function MistsTalentFrame:Constructor()
    self:SetHeight(6 * (BTN_H + ROW_GAP) - ROW_GAP - START_Y)
    self.tierRows    = {}
    self.tierButtons = {}

    for tier = 1, 6 do
        local rowY = START_Y - (tier - 1) * (BTN_H + ROW_GAP)

        -- Row container: stretches full width
        local row = CreateFrame('Frame', nil, self)
        row:SetHeight(BTN_H)
        row:SetPoint('TOPLEFT', 0, rowY)
        row:SetPoint('TOPRIGHT', 0, rowY)

        -- Horizontal stripe background (Blizzard PlayerTalentRowTemplate bg)
        local bg = row:CreateTexture(nil, 'BACKGROUND')
        bg:SetPoint('TOPLEFT',      2, 0)
        bg:SetPoint('BOTTOMRIGHT', -2, 0)
        bg:SetTexture(TALENT_HORIZ)
        bg:SetTexCoord(0, 1, 0.15625, 0.53906250)

        -- Left cap ornament (Blizzard PlayerTalentRowTemplate LeftCap)
        local lcap = row:CreateTexture(nil, 'BORDER')
        lcap:SetSize(CAP_W + 6, BTN_H + 10)
        lcap:SetPoint('LEFT', 0, 0)
        lcap:SetTexture(TALENT_MAIN)
        lcap:SetTexCoord(unpack(TC_LCAP))

        -- Right cap ornament (Blizzard PlayerTalentRowTemplate RightCap)
        local rcap = row:CreateTexture(nil, 'BORDER')
        rcap:SetSize(CAP_W + 6, BTN_H + 10)
        rcap:SetPoint('RIGHT', 0, 0)
        rcap:SetTexture(TALENT_MAIN)
        rcap:SetTexCoord(unpack(TC_RCAP))

        self.tierRows[tier]    = row
        self.tierButtons[tier] = {}

        for col = 1, 3 do
            local btn = CreateFrame('Button', nil, row)
            btn:SetHeight(BTN_H)
            btn.tier = tier
            btn.col  = col

            -- Icon slot background (like PlayerTalentButtonTemplate icon background)
            local slot = btn:CreateTexture(nil, 'BACKGROUND')
            slot:SetSize(ICON_SIZE + 4, ICON_SIZE + 4)
            slot:SetPoint('LEFT', 0, 0)
            slot:SetTexture(TALENT_SLOT)
            btn.slot = slot

            -- Icon (ARTWORK)
            local icon = btn:CreateTexture(nil, 'ARTWORK')
            icon:SetSize(ICON_SIZE, ICON_SIZE)
            icon:SetPoint('CENTER', slot, 'CENTER')
            btn.icon = icon

            -- Name label (GameFontNormalSmall matches PlayerTalentButtonTemplate "name")
            local label = btn:CreateFontString(nil, 'ARTWORK', 'GameFontNormalSmall')
            label:SetPoint('LEFT', slot, 'RIGHT', 5, 0)
            label:SetPoint('RIGHT', btn, 'RIGHT', -3, 0)
            label:SetJustifyH('LEFT')
            label:SetWordWrap(false)
            btn.label = label

            -- Selection highlight (PlayerTalentButtonTemplate "knownSelection", ADD blend)
            local sel = btn:CreateTexture(nil, 'OVERLAY')
            sel:SetPoint('TOPLEFT',      -4,  4)
            sel:SetPoint('BOTTOMRIGHT',   4, -4)
            sel:SetTexture(TALENT_MAIN)
            sel:SetBlendMode('ADD')
            sel:SetTexCoord(unpack(TC_SEL))
            sel:Hide()
            btn.selected = sel

            -- Hover highlight (PlayerTalentButtonTemplate HighlightTexture)
            btn:SetHighlightTexture(TALENT_MAIN, 'ADD')
            btn:GetHighlightTexture():SetTexCoord(unpack(TC_HL))

            local frame = self
            btn:SetScript('OnEnter', function(b)
                if not frame.talent then
                    return
                end
                local spellId = frame.talent:GetTierSpell(b.tier, b.col)
                if spellId then
                    GameTooltip:SetOwner(b, 'ANCHOR_RIGHT')
                    GameTooltip:SetSpellByID(spellId)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript('OnLeave', GameTooltip_Hide)

            self.tierButtons[tier][col] = btn
        end
    end

    self:SetScript('OnSizeChanged', self.Layout)
end

function MistsTalentFrame:Layout()
    local w = self:GetWidth()
    if w <= 0 then return end
    local btnW = (w - 2 * CAP_W) / 3

    for tier = 1, 6 do
        for col = 1, 3 do
            local btn = self.tierButtons[tier][col]
            btn:SetWidth(btnW)
            btn:ClearAllPoints()
            btn:SetPoint('TOPLEFT', CAP_W + (col - 1) * btnW, 0)
        end
    end
end

function MistsTalentFrame:SetTalent(talent)
    self.talent = talent
    self:UpdateDisplay()
end

function MistsTalentFrame:SetActive(isActive)
    for tier = 1, 6 do
        for col = 1, 3 do
            self.tierButtons[tier][col].icon:SetDesaturated(not isActive)
        end
    end
end

function MistsTalentFrame:SetTalentTab(id)
    -- no-op: compatibility shim for old system callers
end

function MistsTalentFrame:UpdateDisplay()
    if not self.talent then
        return
    end

    for tier = 1, 6 do
        local choice = self.talent:GetTierChoice(tier)
        for col = 1, 3 do
            local btn     = self.tierButtons[tier][col]
            local spellId = self.talent:GetTierSpell(tier, col)

            if spellId then
                local name, _, iconId = GetSpellInfo(spellId)
                btn.icon:SetTexture(iconId)
                btn.label:SetText(name)
            else
                btn.icon:SetTexture(nil)
                btn.label:SetText(nil)
            end

            local isSelected = (col == choice and choice > 0)
            btn.selected:SetShown(isSelected)
            -- Desaturate non-chosen talents when tier has a selection (matches TalentFrame_Update)
            SetDesaturation(btn.icon, choice > 0 and not isSelected)
        end
    end
end
