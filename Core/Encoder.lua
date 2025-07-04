-- Encoder.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 2022/9/25 12:07:01
--
---@class ns
local ns = select(2, ...)

local C_Engraving = C_Engraving

local band, rshift, lshift = bit.band, bit.rshift, bit.lshift
local tconcat, tinsert = table.concat, table.insert
local strsub, strbyte, strchar, strrep = string.sub, string.byte, string.char, string.rep
local sort = table.sort
local floor = math.floor
local ripairs = ipairs_reverse

local Encoder = {}
ns.Encoder = Encoder

local R = 128

local NEG = '-'
local LINK_SEP = ':'
local MAJOR_SEP = '!'
local MINOR_SEP = LINK_SEP

function Encoder:EncodeInteger(v)
    v = tonumber(v)
    if not v then
        return
    end
    local s = {}
    local n
    if v < 0 then
        s[1] = NEG
        v = -v
    end
    while v > 0 do
        n = band(v, 127)
        s[#s + 1] = strchar(n + R)
        v = rshift(v, 7)
    end
    return tconcat(s)
end

function Encoder:DecodeInteger(code)
    if not code or code == '' then
        return
    end
    local isNeg = strsub(code, 1, 1) == NEG
    local v = 0
    local n
    for i = #code, isNeg and 2 or 1, -1 do
        n = strbyte(strsub(code, i, i)) - R
        v = lshift(v, 7) + n
    end
    return isNeg and -v or v
end

function Encoder:EncodeItemLink(link)
    local links = strsplittable(':', link)
    links[9] = ''

    local endIndex
    for i, v in ripairs(links) do
        if v ~= '' then
            endIndex = i
            break
        end
    end

    for i = 1, endIndex do
        if links[i] ~= '' then
            links[i] = self:EncodeInteger(links[i]) or ''
        end
    end
    return tconcat(links, LINK_SEP, 1, endIndex)
end

function Encoder:DecodeItemLink(code)
    local links = strsplittable(LINK_SEP, code)
    for i, v in ipairs(links) do
        links[i] = self:DecodeInteger(v) or ''
    end

    local link = tconcat(links, ':')
    if link == '' then
        return
    end
    return 'item:' .. link
end

function Encoder:PackEquips(noEncode)
    local equips = {}
    for i = 1, 18 do
        local link = GetInventoryItemLink('player', i)
        link = link and link:match('item:([%-%d:]+)'):gsub(':+$', '')

        if not noEncode and link then
            link = self:EncodeItemLink(link)
        end
        equips[i] = link or ''
    end
    if noEncode then
        return equips
    else
        return tconcat(equips, MAJOR_SEP)
    end
end

function Encoder:UnpackEquips(code)
    local equips = strsplittable(MAJOR_SEP, code)
    for i, v in ipairs(equips) do
        equips[i] = self:DecodeItemLink(v)
    end
    return equips
end

function Encoder:PackGlyph(group, noEncode)
    group = group or 1
    local data = {}
    for i = 1, 6 do
        local link = GetGlyphLink(i, group)
        local glyphId = link and tonumber(link:match('glyph:%d+:(%d+)'))

        if noEncode then
            data[i] = glyphId
        else
            data[i] = glyphId and self:EncodeInteger(glyphId) or ''
        end
    end
    if noEncode then
        return data
    else
        return tconcat(data, MINOR_SEP)
    end
end

function Encoder:PackGlyphs(noEncode)
    if ns.BUILD < 3 then
        return
    end
    local data = {}
    for i = 1, GetNumTalentGroups() do
        data[i] = self:PackGlyph(i, noEncode)
    end
    if noEncode then
        return data
    else
        return tconcat(data, MAJOR_SEP)
    end
end

function Encoder:UnpackGlyph(code)
    local data = strsplittable(MINOR_SEP, code)
    for i, v in ipairs(data) do
        data[i] = self:DecodeInteger(v)
    end
    return data
end

function Encoder:UnpackGlyphs(code)
    local data = strsplittable(MAJOR_SEP, code)
    for i, v in ipairs(data) do
        data[i] = self:UnpackGlyph(v)
    end
    return data
end

function Encoder:PackRune(i, info)
    local spellId = info.learnedAbilitySpellIDs[info.level]
    local icon = info.iconTexture
    if icon == select(3, GetSpellInfo(spellId)) then
        icon = nil
    end
    return table.concat({
        self:EncodeInteger(i), --
        self:EncodeInteger(spellId), --
        self:EncodeInteger(icon), --
    }, MINOR_SEP)
end

function Encoder:PackRunes()
    if ns.BUILD ~= 1 then
        return
    end
    if C_Engraving.IsEngravingEnabled() then
        local data = {}
        for i = 1, 18 do
            local info = C_Engraving.IsEquipmentSlotEngravable(i) and C_Engraving.GetRuneForEquipmentSlot(i)
            if info then
                tinsert(data, self:PackRune(i, info))
            end
        end
        return tconcat(data, MAJOR_SEP)
    end
end

function Encoder:UnpackRune(code)
    if not code or #code == 0 then
        return
    end
    local slot, spellId, icon = strsplit(MINOR_SEP, code)
    if not slot then
        return
    end
    return { --
        slot = self:DecodeInteger(slot),
        spellId = self:DecodeInteger(spellId),
        icon = self:DecodeInteger(icon),
    }
end

function Encoder:UnpackRunes(code)
    if ns.BUILD ~= 1 then
        return
    end
    if not code then
        return
    end
    local data = strsplittable(MAJOR_SEP, code)
    local runes = {}
    for _, v in ipairs(data) do
        local info = self:UnpackRune(v)
        if info then
            runes[info.slot] = info
        end
    end
    return runes
end

local encodeTalent, decodeTalent
do
    local function talentchar(n)
        n = n + 34
        if n >= 45 then -- '-'
            n = n + 1
        end
        if n >= 58 then -- ':'
            n = n + 1
        end
        if n >= 94 then -- '^'
            n = n + 1
        end
        if n >= 126 then -- '~'
            n = n + 1
        end
        if n >= 127 then
            n = n + 1
        end
        return strchar(n)
    end

    local function talentbyte(n)
        n = strbyte(n)
        if n >= 127 then
            n = n - 1
        end
        if n >= 126 then
            n = n - 1
        end
        if n >= 94 then
            n = n - 1
        end
        if n >= 58 then
            n = n - 1
        end
        if n >= 45 then
            n = n - 1
        end
        return n - 34
    end

    local function tosixstring(n)
        local s = {}
        while n > 0 do
            tinsert(s, 1, tostring(n % 6))
            n = floor(n / 6)
        end
        return tconcat(s)
    end

    encodeTalent = ns.memorize(function(x)
        local l = #x
        if l < 3 then
            x = x .. strrep('0', 3 - l)
        end
        return talentchar(tonumber(x, 6))
    end)

    decodeTalent = ns.memorize(function(x)
        return format('%03s', tosixstring(talentbyte(x)))
    end)
end

function Encoder:EncodeTalent(code)
    return (code:gsub('0+$', ''):gsub('..?.?', encodeTalent))
end

function Encoder:DecodeTalent(code)
    return (code:gsub('.', decodeTalent))
end

local function compare(a, b)
    if a.tab ~= b.tab then
        return a.tab < b.tab
    end
    if a.tier ~= b.tier then
        return a.tier < b.tier
    end
    return a.column < b.column
end

function Encoder:PackTalent(isInspect, group, noEncode)
    local data = {}
    group = group or GetActiveTalentGroup(isInspect)
    for i = 1, GetNumTalentTabs(isInspect) do
        local tab = {}
        for j = 1, GetNumTalents(i, isInspect) do
            local _, _, tier, column, count = GetTalentInfo(i, j, isInspect, nil, group)
            tinsert(tab, {count = tostring(count or 0), tab = i, tier = tier, column = column})
        end
        sort(tab, compare)

        for j, v in ipairs(tab) do
            tab[j] = v.count
        end

        data[i] = tconcat(tab)

        if not noEncode then
            data[i] = self:EncodeTalent(data[i])
        end
    end

    if noEncode then
        return data
    else
        return tconcat(data, MINOR_SEP)
    end
end

function Encoder:PackTalents(isInspect, noEncode)
    local data = {}
    local numGroups = GetNumTalentGroups and GetNumTalentGroups(isInspect) or 1
    for i = 1, numGroups do
        data[i] = self:PackTalent(isInspect, i, noEncode)
    end
    if noEncode then
        return data
    else
        return tconcat(data, MAJOR_SEP)
    end
end

function Encoder:UnpackTalent(code)
    local tabs = strsplittable(MINOR_SEP, code)
    for i, v in ipairs(tabs) do
        tabs[i] = self:DecodeTalent(v)
    end
    return tabs
end

function Encoder:UnpackTalents(code)
    local data = strsplittable(MAJOR_SEP, code)
    for i, v in ipairs(data) do
        data[i] = self:UnpackTalent(v)
    end
    return data
end
