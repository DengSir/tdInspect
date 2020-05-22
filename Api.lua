-- Api.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2/9/2020, 1:02:09 PM

---@type ns
local ns = select(2, ...)

local format = string.format

local GetRealmName = GetRealmName
local UnitFullName = UnitFullName

function ns.strcolor(str, r, g, b)
    return format('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, str)
end

function ns.GetFullName(name, realm)
    if not name then
        return
    end
    if name:find('-', nil, true) then
        return name
    end

    if not realm or realm == '' then
        realm = GetRealmName()
    end
    return name .. '-' .. realm
end

function ns.UnitName(unit)
    return ns.GetFullName(UnitFullName(unit))
end

local summaryCache = {}
function ns.GetTalentSpellSummary(spellId)
    if summaryCache[spellId] == nil then
        local TipScaner = ns.TipScaner
        TipScaner:Clear()
        TipScaner:SetSpellByID(spellId)

        local n = TipScaner:NumLines()
        local passive
        for i = 1, n do
            if TipScaner.L[i]:GetText() == SPELL_PASSIVE then
                passive = true
                break
            end
        end

        if not passive then
            summaryCache[spellId] = false
        elseif n > 2 then
            summaryCache[spellId] = TipScaner.L[n]:GetText()
        end
    end
    return summaryCache[spellId]
end

function ns.IsTalentPassive(spellId)
    return ns.GetTalentSpellSummary(spellId) == false
end
