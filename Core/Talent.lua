-- Talent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/21/2020, 11:22:55 AM
--
---@type ns
local ns = select(2, ...)

local tonumber = tonumber
local tinssert = table.insert
local tconcat = table.concat

---@class Talent: Object
local Talent = ns.Addon:NewClass('Talent')

function Talent:Constructor(class, data)
    self.talents = {}
    self.class = class
    self.data = ns.Talents[class]

    if self.data and self.data.tiers then
        -- MoP tier-based talent system
        if type(data) == 'string' then
            self:ParseMistsTalentV1(data)
        elseif type(data) == 'table' then
            self:ParseMistsTalentV2(data)
        end
    else
        -- Old tree-based talent system
        if type(data) == 'string' then
            self:ParseTalentV1(data)
        elseif type(data) == 'table' then
            self:ParseTalentV2(data)
        end
    end
end

function Talent:ParseMistsTalent(raw)
    raw = raw or ''
    self.specIndex = tonumber(raw:sub(1, 1)) or 0
    self.tierChoices = {}
    for i = 1, 6 do
        self.tierChoices[i] = tonumber(raw:sub(i + 1, i + 1)) or 0
    end
end

function Talent:ParseMistsTalentV1(raw)
    self:ParseMistsTalent(raw)
end

function Talent:ParseMistsTalentV2(data)
    self:ParseMistsTalent(data[1])
end

function Talent:ParseTalentV2(data)
    for i = 1, self:GetNumTalentTabs() do
        self.talents[i] = {}

        local pointsSpent = 0
        for j = 1, self.data[i].numTalents do
            local point = tonumber(data[i]:sub(j, j)) or 0
            self.talents[i][j] = point

            pointsSpent = pointsSpent + point
        end

        self.talents[i].pointsSpent = pointsSpent
    end
end

function Talent:ParseTalentV1(data)
    data = data:gsub('[^%d]+', '')

    local index = 1
    for i = 1, self:GetNumTalentTabs() do
        self.talents[i] = {}

        local pointsSpent = 0
        for j = 1, self.data[i].numTalents do
            local point = tonumber(data:sub(index, index)) or 0
            if point > self.data[i].talents[j].maxRank then
                return self:ParseTalentV1NoOrder(data)
            end
            if point > 0 and pointsSpent < (self.data[i].talents[j].row - 1) * 5 then
                return self:ParseTalentV1NoOrder(data)
            end

            self.talents[i][j] = point
            pointsSpent = pointsSpent + point
            index = index + 1
        end

        self.talents[i].pointsSpent = pointsSpent
    end
end

function Talent:ParseTalentV1NoOrder(data)
    data = data:gsub('[^%d]+', '')

    for i = 1, self:GetNumTalentTabs() do
        self.talents[i] = {}

        local pointsSpent = 0
        for j = 1, self.data[i].numTalents do
            local index = self.data[i].talents[j].index
            local point = tonumber(data:sub(index, index)) or 0
            if point > self.data[i].talents[j].maxRank then
                self.talents = nil
                return
            end
            if point > 0 and pointsSpent < (self.data[i].talents[j].row - 1) * 5 then
                self.talents = nil
                return
            end
            self.talents[i][j] = point
            pointsSpent = pointsSpent + point

        end

        self.talents[i].pointsSpent = pointsSpent
    end
end

function Talent:GetTalentData(tab, index)
    local tabData = self.data[tab]
    return tabData and tabData.talents[index]
end

function Talent:IsMists()
    return self.data and self.data.tiers ~= nil
end

function Talent:GetSpecIndex()
    return self.specIndex or 0
end

function Talent:GetSpecInfo()
    local idx = self.specIndex
    if not idx or idx == 0 then
        return nil
    end
    return self.data and self.data.specs and self.data.specs[idx]
end

function Talent:GetNumSpecs()
    return self.data and self.data.specs and #self.data.specs or 0
end

function Talent:GetNumTiers()
    return self.data and self.data.tiers and #self.data.tiers or 0
end

function Talent:GetTierChoice(tier)
    return self.tierChoices and self.tierChoices[tier] or 0
end

function Talent:GetTierSpell(tier, col)
    local tierData = self.data and self.data.tiers and self.data.tiers[tier]
    if tierData then
        return tierData[col]
    end
end

function Talent:GetNumTalentTabs()
    if self.data and self.data.tiers then
        return 0
    end
    return #self.data
end

function Talent:GetTabInfo(tab)
    local tabData = self.data[tab]
    if tabData then
        return tabData.name, tabData.bg, self.talents[tab] and self.talents[tab].pointsSpent or 0, tabData.icon
    end
end

function Talent:GetNumTalents(tab)
    local tabData = self.data[tab]
    return tabData and tabData.numTalents
end

function Talent:GetTalentInfo(tab, index)
    local talent = self:GetTalentData(tab, index)
    if talent then
        return talent.name, --
        talent.icon, --
        talent.row, --
        talent.column, --
        self.talents[tab][index], --
        talent.maxRank, talent.prereqs, self.talents[tab][index]
    end
end

function Talent:GetTalentLink(tab, index)
    local talent = self:GetTalentData(tab, index)
    if talent and talent.id then
        return format('|cff4e96f7|Htalent:%d:%d|h[%s]|h|r', talent.id, self.talents[tab][index] - 1, talent.name)
    end
end

function Talent:GetTalentPrereqs(tab, index)
    local talent = self:GetTalentData(tab, index)
    if talent then
        return talent.prereqs
    end
end

function Talent:GetTalentRankSpell(tab, index, rank)
    local talent = self:GetTalentData(tab, index)
    if talent then
        if rank == 0 then
            rank = 1
        end
        return talent.ranks[rank]
    end
end

function Talent:ToString()
    if self.data and self.data.tiers then
        -- MoP: return raw 7-char string
        if not self.tierChoices then
            return
        end
        local parts = {tostring(self.specIndex or 0)}
        for i = 1, 6 do
            tinssert(parts, tostring(self.tierChoices[i] or 0))
        end
        return tconcat(parts)
    end

    if not self.talents then
        return
    end

    local tabs = {}
    for _, v in ipairs(self.talents) do
        tinssert(tabs, tconcat(v, ''))
    end
    return tconcat(tabs):gsub('0+$', '')
end
