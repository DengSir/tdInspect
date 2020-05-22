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
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
local GetInventoryItemID = GetInventoryItemID
local GetInventoryItemLink = GetInventoryItemLink
local CanInspect = CanInspect
local NotifyInspect = NotifyInspect
local CheckInteractDistance = CheckInteractDistance
local LoadAddOn = LoadAddOn
local ClearInspectPlayer = ClearInspectPlayer

local HideUIPanel = HideUIPanel

local ALA_PREFIX = 'ATEADD'
local ALA_CMD_LEN = 6

---@type tdInspectInspect
local Inspect = ns.Addon:NewModule('Inspect', 'AceEvent-3.0', 'AceComm-3.0')

function Inspect:OnInitialize()
    self.unitName = nil
    self.db = {}
end

function Inspect:OnEnable()
    self:RegisterEvent('INSPECT_READY')
    self:RegisterEvent('PLAYER_TARGET_CHANGED')
    self:RegisterEvent('GROUP_ROSTER_UPDATE')
    self:RegisterComm(ALA_PREFIX, 'OnAlaCommand')
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

function Inspect:GetUnitClass()
    if self.unit then
        return UnitClassBase(self.unit)
    else
        local db = self.db[self.unitName]
        if db then
            return db.class
        end
    end
end

function Inspect:GetUnitTalent()
    local db = self.db[self.unitName]
    if db then
        return db.talent
    end
end

function Inspect:GetLastUpdate()
    local db = self.db[self.unitName]
    return db and db.timestamp
end

function Inspect:Query(unit, name)
    InspectFrame_LoadUI()
    HideUIPanel(InspectFrame)
    InspectSwitchTabs(1)

    self:SetUnit(unit, name)

    self:SendCommMessage(ALA_PREFIX, '_q_tal', 'WHISPER', self.unitName)

    if unit and CheckInteractDistance(unit, 1) and CanInspect(unit) then
        NotifyInspect(unit)
    else
        self:SendCommMessage(ALA_PREFIX, '_q_equ', 'WHISPER', self.unitName)
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

        db.timestamp = time()

        self:SendMessage('INSPECT_READY', self.unit, name)
    end
end

function Inspect:OnAlaCommand(_, msg, channel, sender)
    local cmd = msg:sub(1, ALA_CMD_LEN)
    if cmd == '_r_equ' then
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

    elseif cmd == '_r_tal' then
        local code = msg:sub(ALA_CMD_LEN + 1)
        code = strsplit('#', code)

        local classFileName, data, level = ns.Ala:Decode(code)

        local name = ns.GetFullName(sender)
        local db = self:BuildCharacterDb(name)

        db.class = classFileName
        db.talent = data
        db.level = level

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
