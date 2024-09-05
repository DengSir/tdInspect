-- Option.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 9/5/2024, 1:39:10 PM
--
---@type ns
local ns = select(2, ...)

local L = ns.L
local tdOptions = LibStub('tdOptions')

---@class Addon
local Addon = ns.Addon

function Addon:SetupOptionFrame()
    local order = 0
    local function orderGen()
        order = order + 1
        return order
    end

    local function fullToggle(name)
        return {type = 'toggle', name = name, width = 'full', order = orderGen()}
    end

    local options = {
        type = 'group',
        name = format('tdInspect - |cff00ff00%s|r', C_AddOns.GetAddOnMetadata('tdInspect', 'Version')),
        get = function(item)
            return self.db.profile[item[#item]]
        end,
        set = function(item, value)
            local key = item[#item]
            self.db.profile[key] = value
            self:SendMessage('TDINSPECT_OPTION_CHANGED', key, value)
        end,
        args = {
            characterGear = fullToggle(L['Show character gear list']),
            inspectGear = fullToggle(L['Show inspect gear list']),
            inspectCompare = fullToggle(L['Show inspect compare']),
            showTalentBackground = fullToggle(L['Show talent background']),
        },
    }

    tdOptions:Register('tdInspect', options)
end

function Addon:OpenOptionFrame()
    tdOptions:Open('tdInspect')
end
