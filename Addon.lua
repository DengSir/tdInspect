-- Addon.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/18/2020, 11:25:23 AM

---@type ns
local ns = select(2, ...)

local _
local pairs, ipairs = pairs, ipairs

local GetSpellInfo = GetSpellInfo
local ShowUIPanel = ShowUIPanel

ns.UI = {}
ns.L = LibStub('AceLocale-3.0'):GetLocale('tdInspect')

local Addon = LibStub('AceAddon-3.0'):NewAddon('tdInspect', 'LibClass-2.0', 'AceEvent-3.0')
ns.Addon = Addon

function Addon:OnInitialize()
    for class, tabs in pairs(ns.Talents) do
        for _, tab in ipairs(tabs) do
            for _, talent in ipairs(tab.talents) do
                talent.name, _, talent.icon = GetSpellInfo(talent.ranks[1])

                for _, id in ipairs(talent.ranks) do
                    ns.GetSpellSummary(id)
                end
            end
        end
    end
end

function Addon:OnEnable()
    self:RegisterEvent('ADDON_LOADED')
    self:RegisterMessage('INSPECT_READY')
end

function Addon:OnModuleCreated(module)
    ns[module:GetName()] = module
end

function Addon:OnClassCreated(class, name)
    local uiName = name:match('^UI%.(.+)$')
    if uiName then
        ns.UI[uiName] = class
        LibStub('AceEvent-3.0'):Embed(class)
    else
        ns[name] = class
    end
end

function Addon:SetupUI()
    self.InspectFrame = ns.UI.InspectFrame:Bind(InspectFrame)
end

function Addon:ADDON_LOADED(_, addon)
    if addon ~= 'Blizzard_InspectUI' then
        return
    end

    self:SetupUI()
    self:UnregisterEvent('ADDON_LOADED')
end

function Addon:INSPECT_READY(_, unit, name)
    if unit == ns.Inspect.unit or name == ns.Inspect.unitName then
        ShowUIPanel(self.InspectFrame)
    end
end
