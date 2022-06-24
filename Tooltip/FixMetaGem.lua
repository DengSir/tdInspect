-- FixMetaGem.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2022/6/23 17:38:17
--
---@class ns
local ns = select(2, ...)

local CONDITION_PARTTERN = '|cff%x%x%x%x%x%x' .. ENCHANT_CONDITION_REQUIRES
local function IsConditionLine(line)
    return line:find(CONDITION_PARTTERN)
end

local function P(text)
    return '|cff%x%x%x%x%x%x' .. ENCHANT_CONDITION_REQUIRES .. text:gsub('%%d', '(%%d+)'):gsub('%%s', '(.+)')
end

local GEM_LOCALE_ENUM = {
    [RED_GEM] = Enum.ItemGemSubclass.Red,
    [YELLOW_GEM] = Enum.ItemGemSubclass.Yellow,
    [BLUE_GEM] = Enum.ItemGemSubclass.Blue,
}

local GEM_CONDITIONS = {
    [P(ENCHANT_CONDITION_MORE_VALUE)] = function(gems, count, gem)
        count = tonumber(count)
        gem = GEM_LOCALE_ENUM[gem]
        return gems[gem] >= count
    end,
    [P(ENCHANT_CONDITION_MORE_COMPARE)] = function(gems, gem1, gem2)
        gem1, gem2 = GEM_LOCALE_ENUM[gem1], GEM_LOCALE_ENUM[gem2]
        return gems[gem1] > gems[gem2]
    end,
}

local function RunCondition(gems, cond, a1, ...)
    if not a1 then
        return
    end
    return cond(gems, a1, ...)
end

local function IsConditionOk(line, gems)
    for k, cond in pairs(GEM_CONDITIONS) do
        local r = RunCondition(gems, cond, line:match(k))
        if r ~= nil then
            return r
        end
    end
end

local function FixColor(line, ok)
    if ok then
        return (line:gsub('|cff%x%x%x%x%x%x', '|cffffffff'))
    else
        return (line:gsub('|cff%x%x%x%x%x%x', '|cff808080'))
    end
end

local function IsInventoryHead(item)
    local equipLoc = select(4, GetItemInfoInstant(item))
    return equipLoc == 'INVTYPE_HEAD'
end

local function HasMetaGem(item)
    for _, itemId in ipairs(ns.GetItemGems(item)) do
        local classId, subClassId = select(6, GetItemInfoInstant(itemId))
        if classId == Enum.ItemClass.Gem and subClassId == Enum.ItemGemSubclass.Meta then
            return true
        end
    end
end

---@param tip LibGameTooltip
local function FindMetaGemLine(tip)
    for i = 2, tip:NumLines() do
        local textLeft = tip:GetFontStringLeft(i)
        local text = textLeft:GetText()

        if IsConditionLine(text) then
            return textLeft, text
        end
    end
end

---@class LineInfo
---@field condition? boolean
---@field text string

---@param tip LibGameTooltip
function ns.FixMetaGem(tip, link)
    if not IsInventoryHead(link) or not HasMetaGem(link) then
        return
    end

    local textLeft, text = FindMetaGemLine(tip)
    if not textLeft or not text then
        return
    end

    ---@type LineInfo[]
    local lines = {}
    local valid = true
    local gems = ns.Inspect:GetEquippedGemCounts()

    for line in gmatch(text, '[^\r\n]+') do
        if not IsConditionLine(line) then
            tinsert(lines, {text = line})
        else
            local ok = IsConditionOk(line, gems)
            tinsert(lines, {condition = true, text = FixColor(line, ok)})
            if not ok then
                valid = false
            end
        end
    end

    for i, info in ipairs(lines) do
        if info.condition then
            lines[i] = info.text
        else
            lines[i] = FixColor(info.text, valid)
        end
    end

    textLeft:SetText(table.concat(lines, '\n'))
end
