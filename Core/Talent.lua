-- Talent.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/19/2020, 4:33:13 PM

---@type ns
local ns = select(2, ...)

---@type tdInspectTalent
local Talent = ns.Addon:NewModule('Talent')

function Talent:OnEnable()

end

function Talent:GetData(class, tabIndex)
    local data = ns.Talents[class]
    return data and data[tabIndex]
end

function Talent:GetTabInfo(class, tabIndex)
    local tab = self:GetData(class, tabIndex)
    if not tab then
        return
    end
    return tab.info.name, tab.info.background
end

function Talent:GetNumTalents(class, tabIndex)
    local tab = self:GetData(class, tabIndex)
    if not tab then
        return
    end
    return tab.numtalents
end

function Talent:GetTalentInfo(class, tabIndex, index)
    local tab = self:GetData(class, tabIndex)
    print(tab)
    if not tab then
        return
    end
    local talent = tab.talents[index]
    return talent and talent.info
end
