-- Core.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/17/2020, 11:08:38 PM

---@type ns
local ns = select(2, ...)

local ipairs = ipairs
local tinsert = tinsert
local select = select
local strsplit = strsplit
local tonumber = tonumber
local time = time

local UnitGUID = UnitGUID
local LoadAddOn = LoadAddOn
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local UnitClassBase = UnitClassBase
local ClearInspectPlayer = ClearInspectPlayer
local GetInventoryItemID = GetInventoryItemID
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetInventoryItemLink = GetInventoryItemLink
local CheckInteractDistance = CheckInteractDistance

local HideUIPanel = HideUIPanel

local ALA_PREFIX = 'ATEADD'
local ALA_CMD_LEN = 6
local PROTO_PREFIX = 'tdInspect'

local Serializer = LibStub('AceSerializer-3.0')

---@type tdInspectInspect
local Inspect = ns.Addon:NewModule('Inspect', 'AceEvent-3.0', 'AceComm-3.0')

function Inspect:OnInitialize()
    self.unitName = nil
    self.db = {}
end

function Inspect:OnEnable()
    local function Deal(sender, ok, cmd, ...)
        if ok then
            return self:OnComm(cmd, ns.GetFullName(sender), ...)
        end
    end

    local function OnComm(_, msg, d, sender)
        return Deal(sender, Serializer:Deserialize(msg))
    end

    self:RegisterEvent('INSPECT_READY')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('GROUP_ROSTER_UPDATE')
    self:RegisterComm(ALA_PREFIX, 'OnAlaCommand')
    self:RegisterComm(PROTO_PREFIX, OnComm)
end

function Inspect:SetUnit(unit, name)
    self.unit = unit
    self.unitName = unit and ns.UnitName(unit) or ns.GetFullName(name)

    INSPECTED_UNIT = unit
    if InspectFrame then
        InspectFrame.unit = unit
    end
end

function Inspect:Clear()
    ClearInspectPlayer()
    self.unitName = nil
    self.unit = nil

    INSPECTED_UNIT = nil
    if InspectFrame then
        InspectFrame.unit = nil
    end
end

function Inspect:GetItemLink(slot)
    local link
    if self.unit then
        link = GetInventoryItemLink(self.unit, slot)
    end
    if not link and self.unitName then
        local db = self.db[self.unitName]
        if db then
            link = db[slot]
        end
    end
    return link
end

function Inspect:IsItemEquipped(itemId)
    for slot = 1, 18 do
        local link = self:GetItemLink(slot)
        if link then
            local id = ns.ItemLinkToId(link)
            if id and id == itemId then
                return true
            end
        end
    end
end

function Inspect:GetDBValue(key)
    local db = self.db[self.unitName]
    return db and db[key]
end

function Inspect:GetUnitClassFileName()
    if self.unit then
        return UnitClassBase(self.unit)
    else
        return ns.GetClassFileName(self:GetDBValue('class'))
    end
end

function Inspect:GetUnitClass()
    if self.unit then
        return (UnitClass(self.unit))
    else
        return ns.GetClassLocale(self:GetDBValue('class'))
    end
end

function Inspect:GetUnitRaceFileName()
    if self.unit then
        return (select(2, UnitRace(self.unit)))
    else
        return ns.GetRaceFileName(self:GetDBValue('race'))
    end
end

function Inspect:GetUnitRace()
    if self.unit then
        return (UnitRace(self.unit))
    else
        return ns.GetRaceLocale(self:GetDBValue('race'))
    end
end

function Inspect:GetUnitLevel()
    if self.unit then
        return UnitLevel(self.unit)
    else
        return self:GetDBValue('level')
    end
end

function Inspect:GetUnitTalent()
    return self:GetDBValue('talent')
end

function Inspect:GetLastUpdate()
    return self:GetDBValue('timestamp')
end

function Inspect:Query(unit, name)
    InspectFrame_LoadUI()
    HideUIPanel(InspectFrame)
    InspectSwitchTabs(1)

    self:SetUnit(unit, name)

    local queryTalent = true
    local queryEquip = true

    if unit and CheckInteractDistance(unit, 1) and CanInspect(unit) then
        NotifyInspect(unit)
    else
        queryEquip = true
    end

    if queryTalent or queryEquip then
        self:SendCommMessage(PROTO_PREFIX, Serializer:Serialize('Q', queryTalent, queryEquip), 'WHISPER', self.unitName)
    end

    if queryTalent then
        self:SendCommMessage(ALA_PREFIX, '_q_tal', 'WHISPER', self.unitName)
        self:SendCommMessage(ALA_PREFIX, '_query', 'WHISPER', self.unitName)
    end

    if queryEquip then
        self:SendCommMessage(ALA_PREFIX, '_q_equ', 'WHISPER', self.unitName)
        self:SendCommMessage(ALA_PREFIX, '_queeq', 'WHISPER', self.unitName)
    end

    self:CheckQuery()
end

function Inspect:CheckQuery()
    if self.db[self.unitName] then
        self:SendMessage('INSPECT_READY', self.unit, self.unitName)
    end
end

function Inspect:BuildCharacterDb(name)
    self.db[name] = self.db[name] or {}
    return self.db[name]
end

function Inspect:INSPECT_READY(_, guid)
    if not self.unit then
        return
    end

    if UnitGUID(self.unit) ~= guid then
        return
    end

    local name = ns.GetFullName(select(6, GetPlayerInfoByGUID(guid)))
    if name then
        local db = self:BuildCharacterDb(name)

        for slot = 0, 18 do
            local link = GetInventoryItemLink(self.unit, slot)
            if link then
                link = link:match('(item:[%-0-9:]+)')
            else
                local id = GetInventoryItemID(self.unit, slot)
                if id then
                    link = 'item:' .. id
                end
            end

            db[slot] = link
        end

        db.class = select(3, UnitClass(self.unit))
        db.race = select(3, UnitRace(self.unit))
        db.level = UnitLevel(self.unit)

        db.timestamp = time()

        self:SendMessage('INSPECT_READY', self.unit, name)
    end
end

local function PackTalent()
    local talents = {}
    for i = 1, 3 do
        for j = 1, GetNumTalents(i) do
            local rank = select(5, GetTalentInfo(i, j))

            tinsert(talents, tostring(rank or 0))
        end
    end

    for i = #talents, 1, -1 do
        if talents[i] ~= '0' then
            break
        else
            talents[i] = nil
        end
    end
    return table.concat(talents)
end

local function PackEquip()
    local equips = {}
    for i = 1, 18 do
        local link = GetInventoryItemLink('player', i)
        if link then
            equips[i] = link:match('item:([%d:]+)'):gsub(':+$', '')
        end
    end
    return equips
end

function Inspect:OnComm(cmd, sender, ...)
    if cmd == 'Q' then
        local queryTalent, queryEquip = ...
        local talent = queryTalent and PackTalent() or nil
        local equip = queryEquip and PackEquip() or nil
        local class = select(3, UnitClass('player'))
        local race = select(3, UnitRace('player'))
        local level = UnitLevel('player')
        local msg = Serializer:Serialize('R', class, race, level, talent, equip)

        self:SendCommMessage(PROTO_PREFIX, msg, 'WHISPER', sender)
    elseif cmd == 'R' then
        local class, race, level, talent, equips = ...

        local db = self:BuildCharacterDb(sender)
        db.timestamp = time()
        db.class = class
        db.race = race
        db.level = level

        if talent then
            db.talent = talent
        end
        if equips then
            for k, v in pairs(equips) do
                db[k] = 'item:' .. v
            end
        end

        if sender == self.unitName then
            self:SendMessage('INSPECT_READY', nil, sender)
            self:SendMessage('INSPECT_TALENT_READY', nil, sender)
        end
    end
end

function Inspect:OnAlaCommand(_, msg, channel, sender)
    local cmd = msg:sub(1, ALA_CMD_LEN)
    if cmd == '_r_equ' or cmd == '_repeq' then
        local sep = msg:sub(ALA_CMD_LEN + 1, ALA_CMD_LEN + 1)
        local data = {strsplit(sep, msg:sub(ALA_CMD_LEN + 2))}

        local name = ns.GetFullName(sender)
        local db = self:BuildCharacterDb(name)

        for i = 1, #data, 2 do
            local slot, link = tonumber(data[i]), data[i + 1]
            if slot and link ~= 'item:-1' then
                db[slot] = link
            end
        end

        db.timestamp = time()

        if name == self.unitName then
            self:SendMessage('INSPECT_READY', nil, name)
        end

    elseif cmd == '_r_tal' or cmd == '_reply' then
        local code = msg:sub(ALA_CMD_LEN + 1)
        code = strsplit('#', code)

        local classFileName, talent, level = ns.Ala:Decode(code)

        local name = ns.GetFullName(sender)
        local db = self:BuildCharacterDb(name)

        db.class = classFileName
        db.level = level
        db.talent = talent

        if name == self.unitName then
            self:SendMessage('INSPECT_TALENT_READY', nil, name)
        end
    end
end

function Inspect:PLAYER_TARGET_CHANGED()
    if self.unit == 'target' then
        self:SetUnit(nil, self.unitName)
        self:SendMessage('INSPECT_TARGET_CHANGED')
    end
end

function Inspect:GROUP_ROSTER_UPDATE()
    if self.unit and self.unitName ~= ns.UnitName(self.unit) then
        self:SetUnit(nil, self.unitName)
        self:SendMessage('INSPECT_TARGET_CHANGED')
    end
end
