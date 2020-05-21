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
        for j = 1, self.data[i].numtalents do
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
    if tabData and tabData.info then
        return tabData.info.name, tabData.info.background, self.talents[tab].pointsSpent
    end
end

function Talent:GetNumTalents(tab)
    local tabData = self.data[tab]
    return tabData and tabData.numtalents
end

function Talent:GetTalentInfo(tab, index)
    local tabData = self.data[tab]
    if not tabData then
        return
    end

    local talent = tabData.talents[index].info

    if talent then
        return talent.name, talent.icon, talent.row, talent.column, talent.ranks, talent.prereqs,
               self.talents[tab][index]
    end
end

function Talent:BuildTooltip(tip, tab, index)
    local talent = self.data[tab].talents[index].info
    tip:SetText(talent.name)
end

function Talent:GetTalentTips(tab, index)
    local tabData = self.data[tab]
    if not tabData then
        return
    end

    local talent = tabData.talents[index].info

    if talent then
        return talent.rankSpells
    end
end
