
---@type ns
local ns = select(2, ...)

local min = min
local max = max
local huge = math.huge
local rshift = bit.rshift

---@type tdInspectTalentFrame
local TalentFrame = ns.Addon:NewClass('UI.TalentFrame', 'Frame')

local MAX_TALENT_TABS = 3
local MAX_NUM_TALENT_TIERS = 7
local NUM_TALENT_COLUMNS = 4
local MAX_NUM_TALENTS = 28
local PLAYER_TALENTS_PER_TIER = 5
local PET_TALENTS_PER_TIER = 3

local TALENT_BUTTON_SIZE_DEFAULT = 32
local INITIAL_TALENT_OFFSET_X_DEFAULT = 35
local INITIAL_TALENT_OFFSET_Y_DEFAULT = 20
local TALENT_GOLD_BORDER_WIDTH = 5

local TALENT_BRANCH_TEXTURECOORDS = {
    up = {[1] = {0.12890625, 0.25390625, 0, 0.484375}, [-1] = {0.12890625, 0.25390625, 0.515625, 1.0}},
    down = {[1] = {0, 0.125, 0, 0.484375}, [-1] = {0, 0.125, 0.515625, 1.0}},
    left = {[1] = {0.2578125, 0.3828125, 0, 0.5}, [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
    right = {[1] = {0.2578125, 0.3828125, 0, 0.5}, [-1] = {0.2578125, 0.3828125, 0.5, 1.0}},
    topright = {[1] = {0.515625, 0.640625, 0, 0.5}, [-1] = {0.515625, 0.640625, 0.5, 1.0}},
    topleft = {[1] = {0.640625, 0.515625, 0, 0.5}, [-1] = {0.640625, 0.515625, 0.5, 1.0}},
    bottomright = {[1] = {0.38671875, 0.51171875, 0, 0.5}, [-1] = {0.38671875, 0.51171875, 0.5, 1.0}},
    bottomleft = {[1] = {0.51171875, 0.38671875, 0, 0.5}, [-1] = {0.51171875, 0.38671875, 0.5, 1.0}},
    tdown = {[1] = {0.64453125, 0.76953125, 0, 0.5}, [-1] = {0.64453125, 0.76953125, 0.5, 1.0}},
    tup = {[1] = {0.7734375, 0.8984375, 0, 0.5}, [-1] = {0.7734375, 0.8984375, 0.5, 1.0}},
}

local TALENT_ARROW_TEXTURECOORDS = {
    top = {[1] = {0, 0.5, 0, 0.5}, [-1] = {0, 0.5, 0.5, 1.0}},
    right = {[1] = {1.0, 0.5, 0, 0.5}, [-1] = {1.0, 0.5, 0.5, 1.0}},
    left = {[1] = {0.5, 1.0, 0, 0.5}, [-1] = {0.5, 1.0, 0.5, 1.0}},
}

function TalentFrame:Constructor()
    self.class = 'ROGUE'
    self.tabIndex = 3

    self.branches = {}
    self.buttons = {}
    self.brancheTextures = {}
    self.arrowTextures = {}

    self.talentButtonSize = 37
    self.initialOffsetX = 0
    self.initialOffsetY = 0
    self.buttonSpacingX = 48
    self.buttonSpacingY = 48
    self.arrowInsetX = 2
    self.arrowInsetY = 2

    self.ArrowParent = CreateFrame('Frame', nil, self)
    self.ArrowParent:SetAllPoints(true)
    self.ArrowParent:SetFrameLevel(self:GetFrameLevel() + 100)

    for i = 1, MAX_NUM_TALENT_TIERS do
        self.branches[i] = {}
        for j = 1, NUM_TALENT_COLUMNS do
            self.branches[i][j] = {
                id = nil,
                up = 0,
                left = 0,
                right = 0,
                down = 0,
                leftArrow = 0,
                rightArrow = 0,
                topArrow = 0,
            }
        end
    end
end

function TalentFrame:GetTalentButton(i)
    if not self.buttons[i] then
        local button = CreateFrame('Button', nil, self, 'ItemButtonTemplate')
        button:SetSize(self.talentButtonSize, self.talentButtonSize)

        local Slot = button:CreateTexture(nil, 'ARTWORK', 'Talent-SingleBorder')
        Slot:SetPoint('TOPLEFT', -1, 0)

        local SlotShadow = button:CreateTexture(nil, 'ARTWORK', 'Talent-SingleBorder-Shadow')
        SlotShadow:SetPoint('TOPLEFT', -4, 3)

        local GoldBorder = button:CreateTexture(nil, 'ARTWORK', 'Talent-GoldMedal-Border')
        GoldBorder:SetPoint('TOPLEFT', -7, 7)

        local RankBorder = button:CreateTexture(nil, 'OVERLAY', 'Talent-PointBg')
        RankBorder:SetPoint('CENTER', self, 'BOTTOMRIGHT', -3, 3)

        local Rank = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
        Rank:SetPoint('CENTER', RankBorder, 'CENTER')

        button.Slot = Slot
        button.SlotShadow = SlotShadow
        button.GoldBorder = GoldBorder
        button.RankBorder = RankBorder
        button.Rank = Rank

        self.buttons[i] = button
    end
    return self.buttons[i]
end

function TalentFrame:Update()
    -- local preview = GetCVarBool('previewTalentsOption')
    local preview = false
    local talentButtonSize = self.talentButtonSize or TALENT_BUTTON_SIZE_DEFAULT
    local initialOffsetX = self.initialOffsetX or INITIAL_TALENT_OFFSET_X_DEFAULT
    local initialOffsetY = self.initialOffsetY or INITIAL_TALENT_OFFSET_Y_DEFAULT
    local buttonSpacingX = self.buttonSpacingX or (2 * talentButtonSize - 1)
    local buttonSpacingY = self.buttonSpacingY or (2 * talentButtonSize - 1)

    -- get active talent group
    local isActiveTalentGroup
    if self.inspect then
        -- even though we have inspection data for more than one talent group, we're only showing one for now
        isActiveTalentGroup = true
    else
        -- isActiveTalentGroup = self.talentGroup == GetActiveTalentGroup(self.inspect, self.pet)
        isActiveTalentGroup = true
    end
    -- Setup Frame
    local base
    -- local id, name, description, icon, pointsSpent, background, previewPointsSpent, isUnlocked =
    --     GetTalentTabInfo(selectedTab, self.inspect, self.pet, self.talentGroup)
    local isUnlocked = false
    local pointsSpent = 0
    local previewPointsSpent = 0
    local name, background = ns.Talent:GetTabInfo(self.class, self.tabIndex)
    if name then
        base = 'Interface\\TalentFrame\\' .. background .. '-'
    else
        -- temporary default for classes without talents poor guys
        base = 'Interface\\TalentFrame\\MageFire-'
    end
    -- desaturate the background if this isn't the active talent group
    -- local backgroundPiece = _G[talentFrameName .. 'BackgroundTopLeft']
    -- backgroundPiece:SetTexture(base .. 'TopLeft')
    -- SetDesaturation(backgroundPiece, not isActiveTalentGroup)
    -- backgroundPiece = _G[talentFrameName .. 'BackgroundTopRight']
    -- backgroundPiece:SetTexture(base .. 'TopRight')
    -- SetDesaturation(backgroundPiece, not isActiveTalentGroup)
    -- backgroundPiece = _G[talentFrameName .. 'BackgroundBottomLeft']
    -- backgroundPiece:SetTexture(base .. 'BottomLeft')
    -- SetDesaturation(backgroundPiece, not isActiveTalentGroup)
    -- backgroundPiece = _G[talentFrameName .. 'BackgroundBottomRight']
    -- backgroundPiece:SetTexture(base .. 'BottomRight')
    -- SetDesaturation(backgroundPiece, not isActiveTalentGroup)

    local numTalents = ns.Talent:GetNumTalents(self.class, self.tabIndex)
    -- Just a reminder error if there are more talents than available buttons
    if numTalents > MAX_NUM_TALENTS then
        message('Too many talents in talent frame!')
    end

    -- get unspent talent points
    local unspentPoints = self:GetUnspentTalentPoints()
    -- compute tab points spent if any
    local tabPointsSpent
    if self.pointsSpent and self.previewPointsSpent then
        tabPointsSpent = self.pointsSpent + self.previewPointsSpent
    else
        tabPointsSpent = pointsSpent + previewPointsSpent
    end

    self:ResetBranches()
    local forceDesaturated, tierUnlocked
    for i = 1, MAX_NUM_TALENTS do
        local button = self:GetTalentButton(i)
        if i <= numTalents then
            -- Set the button info
            -- local name, iconTexture, tier, column, rank, maxRank, meetsPrereq, previewRank, meetsPreviewPrereq,
            --       isExceptional, goldBorder = GetTalentInfo(selectedTab, i, self.inspect, self.pet, self.talentGroup)

            local info = ns.Talent:GetTalentInfo(self.class, self.tabIndex, i)
            local name = info.name
            local iconTexture = info.icon
            local tier = info.row
            local column = info.column
            local maxRank = info.ranks
            local goldBorder = false
            local isExceptional = false
            local previewRank = 0
            local rank = 0
            local meetsPreviewPrereq = not not info.prereqs
            local meetsPrereq = not not info.prereqs

            -- Temp hack - For now, we are just ignoring the "goldBorder" flag and putting the gold border on any "exceptional" talents
            goldBorder = isExceptional

            if name and tier <= MAX_NUM_TALENT_TIERS then
                local displayRank
                if preview then
                    displayRank = previewRank
                else
                    displayRank = rank
                end

                button.Rank:SetText(displayRank)
                self:SetButtonLocation(button, tier, column, talentButtonSize, initialOffsetX, initialOffsetY,
                                       buttonSpacingX, buttonSpacingY)
                self.branches[tier][column].id = button:GetID()

                -- If player has no talent points or this is the inactive talent group then show only talents with points in them
                if (unspentPoints <= 0 or not isActiveTalentGroup) and displayRank == 0 then
                    forceDesaturated = 1
                else
                    forceDesaturated = nil
                end

                -- is this talent's tier unlocked?
                if isUnlocked and (tier - 1) * (self.pet and PET_TALENTS_PER_TIER or PLAYER_TALENTS_PER_TIER) <=
                    tabPointsSpent then
                    tierUnlocked = 1
                else
                    tierUnlocked = nil
                end

                SetItemButtonTexture(button, iconTexture)

                if goldBorder and button.GoldBorder then
                    button.GoldBorder:Show()
                    button.Slot:Hide()
                    button.SlotShadow:Hide()
                else
                    if button.GoldBorder then
                        button.GoldBorder:Hide()
                    end
                    button.Slot:Show()
                    button.SlotShadow:Show()
                end

                -- Talent must meet prereqs or the player must have no points to spend
                -- local prereqsSet = self:SetPrereqs(tier, column, forceDesaturated, tierUnlocked, preview,
                --                                    GetTalentPrereqs(selectedTab, i, self.inspect, self.pet,
                --                                                     self.talentGroup))
                local prereqsSet = self:SetPrereqs(tier, column, forceDesaturated, tierUnlocked, preview, info.prereqs)
                if prereqsSet and ((preview and meetsPreviewPrereq) or (not preview and meetsPrereq)) then
                    SetItemButtonDesaturated(button, nil)
                    button:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
                    button:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square', 'ADD')
                    button.RankBorder:Show()
                    button.RankBorder:SetVertexColor(1, 1, 1)
                    button.Rank:Show()

                    button.GoldBorder:SetDesaturated(nil)

                    if displayRank < maxRank then
                        -- Rank is green if not maxed out
                        button.Rank:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b)

                        if (button.RankBorderGreen) then
                            button.RankBorder:Hide()
                            button.RankBorderGreen:Show()
                            button.Slot:SetVertexColor(1.0, 0.82, 0)
                        else
                            button.Slot:SetVertexColor(0.1, 1.0, 0.1)
                        end

                        if button.GlowBorder then
                            if (unspentPoints > 0 and not goldBorder) then
                                button.GlowBorder:Show()
                            else
                                button.GlowBorder:Hide()
                            end
                        end

                        if button.GoldBorderGlow then
                            if (unspentPoints > 0 and goldBorder) then
                                button.GoldBorderGlow:Show()
                            else
                                button.GoldBorderGlow:Hide()
                            end
                        end
                    else
                        button.Slot:SetVertexColor(1.0, 0.82, 0)
                        button.Rank:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
                        if (button.GlowBorder) then
                            button.GlowBorder:Hide()
                        end
                        if (button.GoldBorderGlow) then
                            button.GoldBorderGlow:Hide()
                        end
                        if (button.RankBorderGreen) then
                            button.RankBorderGreen:Hide()
                        end
                    end
                else
                    SetItemButtonDesaturated(button, 1)
                    button:SetPushedTexture(nil)
                    button:SetHighlightTexture(nil)
                    button.GoldBorder:SetDesaturated(1)
                    button.Slot:SetVertexColor(0.5, 0.5, 0.5)
                    if rank == 0 then
                        button.RankBorder:Hide()
                        button.Rank:Hide()
                    else
                        button.RankBorder:SetVertexColor(0.5, 0.5, 0.5)
                        button.Rank:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b)
                    end
                    if button.GlowBorder then
                        button.GlowBorder:Hide()
                    end
                    if button.GoldBorderGlow then
                        button.GoldBorderGlow:Hide()
                    end
                    if button.RankBorderGreen then
                        button.RankBorderGreen:Hide()
                    end
                end

                self.branches[tier][column].goldBorder = goldBorder

                button:Show()
            else
                button:Hide()
            end
        else
            if button then
                button:Hide()
            end
        end
    end

    -- Draw the prereq branches
    local node
    local textureIndex = 1
    local xOffset, yOffset
    local texCoords
    local tempNode
    self:ResetBranchTextureCount()
    self:ResetArrowTextureCount()
    for i = 1, MAX_NUM_TALENT_TIERS do
        for j = 1, NUM_TALENT_COLUMNS do
            node = self.branches[i][j]

            -- Setup offsets
            xOffset = ((j - 1) * buttonSpacingX) + initialOffsetX + (self.branchOffsetX or 0)
            yOffset = -((i - 1) * buttonSpacingY) - initialOffsetY + (self.branchOffsetY or 0)

            -- Always draw Right and Down branches, never draw Left and Up branches as those will be drawn by the preceeding talent
            if node.down ~= 0 then
                self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['down'][node.down], xOffset,
                                      yOffset - talentButtonSize, talentButtonSize, buttonSpacingY - talentButtonSize)
            end
            if node.right ~= 0 then
                self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['right'][node.right],
                                      xOffset + talentButtonSize, yOffset, buttonSpacingX - talentButtonSize,
                                      talentButtonSize)
            end

            if node.id then
                -- There is a talent in this slot; draw arrows
                local arrowInsetX, arrowInsetY = (self.arrowInsetX or 0), (self.arrowInsetY or 0)
                if node.goldBorder then
                    arrowInsetX = arrowInsetX - TALENT_GOLD_BORDER_WIDTH
                    arrowInsetY = arrowInsetY - TALENT_GOLD_BORDER_WIDTH
                end

                if node.rightArrow ~= 0 then
                    self:SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS['right'][node.rightArrow],
                                         xOffset + talentButtonSize / 2 - arrowInsetX, yOffset)
                end
                if node.leftArrow ~= 0 then
                    self:SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS['left'][node.leftArrow],
                                         xOffset - talentButtonSize / 2 + arrowInsetX, yOffset)
                end
                if node.topArrow ~= 0 then
                    self:SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS['top'][node.topArrow], xOffset,
                                         yOffset + talentButtonSize / 2 - arrowInsetY)
                end
            else
                -- No talent; draw branches
                if node.up ~= 0 and node.left ~= 0 and node.right ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['tup'][node.up], xOffset, yOffset)
                elseif node.down ~= 0 and node.left ~= 0 and node.right ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['tdown'][node.down], xOffset, yOffset)
                elseif node.left ~= 0 and node.down ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['topright'][node.left], xOffset, yOffset)
                elseif node.left ~= 0 and node.up ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['bottomright'][node.left], xOffset, yOffset)
                elseif node.left ~= 0 and node.right ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['right'][node.right],
                                          xOffset + talentButtonSize, yOffset)
                elseif node.right ~= 0 and node.down ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['topleft'][node.right], xOffset, yOffset)
                elseif node.right ~= 0 and node.up ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['bottomleft'][node.right], xOffset, yOffset)
                elseif node.up ~= 0 and node.down ~= 0 then
                    self:SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS['up'][node.up], xOffset, yOffset)
                end
            end
        end
    end
    -- Hide any unused branch textures
    for i = self:GetBranchTextureCount(), #self.brancheTextures do
        self.brancheTextures[i]:Hide()
    end
    -- Hide and unused arrowl textures
    for i = self:GetArrowTextureCount(), #self.arrowTextures do
        self.arrowTextures[i]:Hide()
    end
end

function TalentFrame:SetArrowTexture(tier, column, texCoords, xOffset, yOffset)
    local arrowTexture = self:GetArrowTexture()
    arrowTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
    arrowTexture:SetPoint('TOPLEFT', arrowTexture:GetParent(), 'TOPLEFT', xOffset, yOffset)
end

function TalentFrame:SetBranchTexture(tier, column, texCoords, xOffset, yOffset, xSize, ySize)
    local branchTexture = self:GetBranchTexture()
    branchTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4])
    branchTexture:SetPoint('TOPLEFT', branchTexture:GetParent(), 'TOPLEFT', xOffset, yOffset)
    branchTexture:SetWidth(xSize or self.talentButtonSize or TALENT_BUTTON_SIZE_DEFAULT)
    branchTexture:SetHeight(ySize or self.talentButtonSize or TALENT_BUTTON_SIZE_DEFAULT)
end

function TalentFrame:GetArrowTexture()
    local texture = self.arrowTextures[self.arrowIndex]
    if not texture then
        texture = self.ArrowParent:CreateTexture(nil, 'BACKGROUND')
        texture:SetSize(37, 37)
        texture:SetTexture([[Interface\TalentFrame\UI-TalentArrows]])
        self.arrowTextures[self.arrowIndex] = texture
        self.arrowIndex = self.arrowIndex + 1
    end
    texture:Show()
    return texture
end

function TalentFrame:GetBranchTexture()
    local texture = self.brancheTextures[self.textureIndex]
    if not texture then
        texture = self:CreateTexture(nil, 'BACKGROUND')
        texture:SetSize(30, 30)
        texture:SetTexture([[Interface\TalentFrame\UI-TalentBranches]])
        self.brancheTextures[self.textureIndex] = texture
        self.textureIndex = self.textureIndex + 1
    end
    texture:Show()
    return texture
end

function TalentFrame:ResetArrowTextureCount()
    self.arrowIndex = 1
end

function TalentFrame:ResetBranchTextureCount()
    self.textureIndex = 1
end

function TalentFrame:GetArrowTextureCount()
    return self.arrowIndex
end

function TalentFrame:GetBranchTextureCount()
    return self.textureIndex
end

---@param prereqs tdInspectTalentPrereqs[]
function TalentFrame:SetPrereqs(buttonTier, buttonColumn, forceDesaturated, tierUnlocked, preview, prereqs)
    local requirementsMet = tierUnlocked and not forceDesaturated

    if prereqs then
        for i, v in ipairs(prereqs) do
            local tier, column, isLearnable, isPreviewLearnable = v.row, v.column, false, false
            if forceDesaturated or (preview and not isPreviewLearnable) or (not preview and not isLearnable) then
                requirementsMet = nil
            end
            self:DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet)
        end
    end
    -- for i = 1, select('#', ...), 4 do
    --     local tier, column, isLearnable, isPreviewLearnable = select(i, ...)
    --     if (forceDesaturated or (preview and not isPreviewLearnable) or (not preview and not isLearnable)) then
    --         requirementsMet = nil
    --     end
    --     self:DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet)
    -- end
    return requirementsMet
end

function TalentFrame:DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet)
    if requirementsMet then
        requirementsMet = 1
    else
        requirementsMet = -1
    end

    -- Check to see if are in the same column
    if buttonColumn == column then
        -- Check for blocking talents
        if buttonTier - tier > 1 then
            -- If more than one tier difference
            for i = tier + 1, buttonTier - 1 do
                if self.branches[i][buttonColumn].id then
                    -- If there's an id, there's a blocker
                    message('Error this layout is blocked vertically ' .. self.branches[buttonTier][i].id)
                    return
                end
            end
        end

        -- Draw the lines
        for i = tier, buttonTier - 1 do
            self.branches[i][buttonColumn].down = requirementsMet
            if i + 1 <= buttonTier - 1 then
                self.branches[i + 1][buttonColumn].up = requirementsMet
            end
        end

        -- Set the arrow
        self.branches[buttonTier][buttonColumn].topArrow = requirementsMet
        return
    end
    -- Check to see if they're in the same tier
    if buttonTier == tier then
        local left = min(buttonColumn, column)
        local right = max(buttonColumn, column)

        -- See if the distance is greater than one space
        if right - left > 1 then
            -- Check for blocking talents
            for i = left + 1, right - 1 do
                if self.branches[tier][i].id then
                    -- If there's an id, there's a blocker
                    message('there\'s a blocker ' .. tier .. ' ' .. i)
                    return
                end
            end
        end
        -- If we get here then we're in the clear
        for i = left, right - 1 do
            self.branches[tier][i].right = requirementsMet
            self.branches[tier][i + 1].left = requirementsMet
        end
        -- Determine where the arrow goes
        if buttonColumn < column then
            self.branches[buttonTier][buttonColumn].rightArrow = requirementsMet
        else
            self.branches[buttonTier][buttonColumn].leftArrow = requirementsMet
        end
        return
    end
    -- Now we know the prereq is diagonal from us
    local left = min(buttonColumn, column)
    local right = max(buttonColumn, column)
    -- Don't check the location of the current button
    if left == column then
        left = left + 1
    else
        right = right - 1
    end
    -- Check for blocking talents
    local blocked = nil
    for i = left, right do
        if self.branches[tier][i].id then
            -- If there's an id, there's a blocker
            blocked = 1
        end
    end
    left = min(buttonColumn, column)
    right = max(buttonColumn, column)
    if not blocked then
        self.branches[tier][buttonColumn].down = requirementsMet
        self.branches[buttonTier][buttonColumn].up = requirementsMet

        for i = tier, buttonTier - 1 do
            self.branches[i][buttonColumn].down = requirementsMet
            self.branches[i + 1][buttonColumn].up = requirementsMet
        end

        for i = left, right - 1 do
            self.branches[tier][i].right = requirementsMet
            self.branches[tier][i + 1].left = requirementsMet
        end
        -- Place the arrow
        self.branches[buttonTier][buttonColumn].topArrow = requirementsMet
        return
    end
    -- If we're here then we were blocked trying to go vertically first so we have to go over first, then up
    if left == buttonColumn then
        left = left + 1
    else
        right = right - 1
    end
    -- Check for blocking talents
    for i = left, right do
        if self.branches[buttonTier][i].id then
            -- If there's an id, then throw an error
            message('Error, this layout is undrawable ' .. self.branches[buttonTier][i].id)
            return
        end
    end
    -- If we're here we can draw the line
    left = min(buttonColumn, column)
    right = max(buttonColumn, column)
    -- TALENT_BRANCH_ARRAY[tier][column].down = requirementsMet;
    -- TALENT_BRANCH_ARRAY[buttonTier][column].up = requirementsMet;

    for i = tier, buttonTier - 1 do
        self.branches[i][column].up = requirementsMet
        self.branches[i + 1][column].down = requirementsMet
    end

    -- Determine where the arrow goes
    if buttonColumn < column then
        self.branches[buttonTier][buttonColumn].rightArrow = requirementsMet
    else
        self.branches[buttonTier][buttonColumn].leftArrow = requirementsMet
    end
end

-- Helper functions

function TalentFrame:GetUnspentTalentPoints()
    -- local talentPoints = GetUnspentTalentPoints(self.inspect, self.pet, self.talentGroup)
    -- local unspentPoints = talentPoints - GetGroupPreviewTalentPointsSpent(self.pet, self.talentGroup)
    -- return unspentPoints
    -- TODO:
    return 0
end

function TalentFrame:SetButtonLocation(button, tier, column, talentButtonSize, initialOffsetX, initialOffsetY,
                                       buttonSpacingX, buttonSpacingY)
    column = (column - 1) * buttonSpacingX + initialOffsetX
    tier = -(tier - 1) * buttonSpacingY - initialOffsetY
    button:SetPoint('TOPLEFT', button:GetParent(), 'TOPLEFT', column, tier)
end

function TalentFrame:ResetBranches()
    local node
    for i = 1, MAX_NUM_TALENT_TIERS do
        for j = 1, NUM_TALENT_COLUMNS do
            node = self.branches[i][j]
            node.id = nil
            node.up = 0
            node.down = 0
            node.left = 0
            node.right = 0
            node.rightArrow = 0
            node.leftArrow = 0
            node.topArrow = 0
        end
    end
end
