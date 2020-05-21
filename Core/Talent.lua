-- Talent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/21/2020, 11:22:55 AM

---@type ns
local ns = select(2, ...)

---@type tdInspectTalent
local Talent = ns.Addon:NewClass('Talent')

function Talent:Constructor(class, data)
    self.talents = {}
    self.class = class
    self.data = ns.Talents[class]
    self:ParseTalent(data)
end

function Talent:ParseTalent(data)
    data = data:gsub('[^%d]+', '')

    local index = 1
    for i = 1, 3 do
        self.talents[i] = {}

        local pointsSpent = 0
        for j = 1, self.data[i].numTalents do
            local point = tonumber(data:sub(index, index)) or 0
            self.talents[i][j] = point
            pointsSpent = pointsSpent + point
            index = index + 1
        end

        self.talents[i].pointsSpent = pointsSpent
    end
end

function Talent:GetTabInfo(tab)
    local tabData = self.data[tab]
    if tabData then
        return tabData.name, tabData.background, self.talents[tab].pointsSpent
    end
end

function Talent:GetNumTalents(tab)
    local tabData = self.data[tab]
    return tabData and tabData.numTalents
end

function Talent:GetTalentInfo(tab, index)
    local tabData = self.data[tab]
    if not tabData then
        return
    end

    local talent = tabData.talents[index]
    if talent then
        return talent.name, talent.icon, talent.row, talent.column, talent.maxRank, talent.prereqs,
               self.talents[tab][index]
    end
end

function Talent:GetTalentTips(tab, index)
    local tabData = self.data[tab]
    if not tabData then
        return
    end

    local talent = tabData.talents[index]
    if talent then
        return talent.ranks
    end
end
