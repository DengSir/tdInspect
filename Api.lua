-- Api.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2/9/2020, 1:02:09 PM
---@type ns
local ns = select(2, ...)

local CIS = LibStub('LibClassicItemSets-1.0')

local ipairs = ipairs
local tonumber = tonumber
local format = string.format

local GetItemInfo = GetItemInfo
local GetRealmName = GetRealmName
local UnitFullName = UnitFullName

local GameTooltip = GameTooltip

local SPELL_PASSIVE = SPELL_PASSIVE
local ITEM_SET_BONUS_GRAY_P = '^' .. ITEM_SET_BONUS_GRAY:gsub('%%s', '(.+)'):gsub('%(%%d%)', '%%((%%d+)%%)') .. '$'
local ITEM_SET_BONUS_P = '^' .. format(ITEM_SET_BONUS, '(.+)')

local function memorize(func)
    local cache = {}

    return function(k, ...)
        if not k then
            return
        end
        if not cache[k] then
            cache[k] = func(k, ...)
        end
        return cache[k]
    end
end

ns.memorize = memorize

function ns.strcolor(str, r, g, b)
    return format('|cff%02x%02x%02x%s|r', r * 255, g * 255, b * 255, str)
end

function ns.ItemLinkToId(link)
    return link and (tonumber(link) or tonumber(link:match('item:(%d+)')))
end

ns.GetClassFileName = memorize(function(classId)
    if not classId then
        return
    end
    local classInfo = C_CreatureInfo.GetClassInfo(classId)
    dump(classInfo)
    return classInfo and classInfo.classFile
end)

ns.GetClassLocale = memorize(function(classId)
    if not classId then
        return
    end
    local classInfo = C_CreatureInfo.GetClassInfo(classId)
    return classInfo and classInfo.className
end)

ns.GetRaceFileName = memorize(function(raceId)
    if not raceId then
        return
    end
    local raceInfo = C_CreatureInfo.GetRaceInfo(raceId)
    return raceInfo and raceInfo.clientFileString
end)

ns.GetRaceLocale = memorize(function(raceId)
    if not raceId then
        return
    end
    local raceInfo = C_CreatureInfo.GetRaceInfo(raceId)
    return raceInfo and raceInfo.raceName
end)

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

local function MatchBonus(text)
    local count, summary = text:match(ITEM_SET_BONUS_GRAY_P)
    if count then
        return summary, tonumber(count)
    end

    return text:match(ITEM_SET_BONUS_P)
end

function ns.FixInspectItemTooltip()
    local id = ns.ItemLinkToId(select(2, GameTooltip:GetItem()))
    if not id then
        return
    end

    local setId = CIS:GetItemSetForItemID(id)
    if not setId then
        return
    end

    local setName = CIS:GetSetName(setId)
    if not setName then
        return
    end

    local items = CIS:GetItems(setId)
    if not items then
        return
    end

    local itemNames = {}
    local equippedCount = 0
    local itemsCount = #items
    local setNameLinePattern = '^(' .. setName .. '.+)(%d+)/(%d+)(.+)$'

    for _, itemId in ipairs(items) do
        if ns.Inspect:IsItemEquipped(itemId) then
            local name = GetItemInfo(itemId)
            if not name then
                return
            end
            itemNames[name] = (itemNames[name] or 0) + 1
            equippedCount = equippedCount + 1
        end
    end

    local setLine
    local firstBonusLine

    for i = 2, GameTooltip:NumLines() do
        local textLeft = _G['GameTooltipTextLeft' .. i]
        local text = textLeft:GetText()

        if not setLine then
            local prefix, n, maxCount, suffix = text:match(setNameLinePattern)
            if prefix then
                setLine = i
                textLeft:SetText(prefix .. equippedCount .. '/' .. maxCount .. suffix)
            end
        elseif i - setLine <= itemsCount + 1 then
            local line = text:trim()
            local n = itemNames[line]
            if n and n > 0 then
                textLeft:SetTextColor(1, 1, 0.6)
                itemNames[line] = n > 1 and n - 1 or nil
            else
                textLeft:SetTextColor(0.5, 0.5, 0.5)
            end
        else
            local summary, count = MatchBonus(text)
            if summary then
                if not firstBonusLine then
                    firstBonusLine = i
                end

                if not count and firstBonusLine then
                    count = ns.SetsBouns[id] and ns.SetsBouns[id][i - firstBonusLine + 1]
                end

                if count then
                    if equippedCount >= count then
                        textLeft:SetText(ITEM_SET_BONUS:format(summary))
                        textLeft:SetTextColor(0.1, 1, 0.1)
                    else
                        textLeft:SetText(ITEM_SET_BONUS_GRAY:format(count, summary))
                        textLeft:SetTextColor(0.5, 0.5, 0.5)
                    end
                end
            end
        end
    end

    GameTooltip:Show()
end
