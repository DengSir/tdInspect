-- Cache.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/22/2020, 1:19:12 AM

---@type ns
local ns = select(2, ...)

local tip = CreateFrame('GameTooltip')
tip:SetOwner(WorldFrame, 'ANCHOR_NONE')

local lcache, rcache = {}, {}
for i = 1, 30 do
    lcache[i], rcache[i] = tip:CreateFontString(), tip:CreateFontString()
    lcache[i]:SetFontObject(GameFontNormal)
    rcache[i]:SetFontObject(GameFontNormal)
    tip:AddFontStrings(lcache[i], rcache[i])
end

local cache = {}

local function Build(id)
    if cache[id] == nil then
        if not tip:IsOwned(WorldFrame) then
            tip:SetOwner(WorldFrame, 'ANCHOR_NONE')
        end
        tip:ClearLines()
        tip:SetSpellByID(id)

        local num = tip:NumLines()
        if num <= 2 then
            return
        end

        cache[id] = false

        for i = 1, num do
            if lcache[i]:GetText() == SPELL_PASSIVE then
                cache[id] = lcache[num]:GetText()
                break
            end
        end
    end
    return cache[id]
end

function ns.GetSpellSummary(id)
    return Build(id)
end
