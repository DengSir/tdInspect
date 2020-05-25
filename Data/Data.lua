-- DataApi.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/25/2020, 4:43:38 PM

---@type ns
local ns = select(2, ...)

ns.Talents = {}

function ns.Data()
    ns.Data = nil

    local CURRENT

    local function CreateClass(classFileName)
        CURRENT = {}
        ns.Talents[classFileName] = CURRENT
    end

    local function CreateTab(background, numTalents)
        tinsert(CURRENT, {background = background, numTalents = numTalents, talents = {}})
    end

    local function CreateTalentInfo(row, column, maxRank)
        local tab = CURRENT[#CURRENT]
        tinsert(tab.talents, {row = row, column = column, maxRank = maxRank})
    end

    local function FillTalentRanks(ranks)
        local tab = CURRENT[#CURRENT]
        local talent = tab.talents[#tab.talents]
        talent.ranks = ranks
    end

    local function FillTalentPrereq(row, column)
        local tab = CURRENT[#CURRENT]
        local talent = tab.talents[#tab.talents]
        talent.prereqs = talent.prereqs or {}
        tinsert(talent.prereqs, {row = row, column = column})
    end

    local function SetTabName(locale, name)
        local tab = CURRENT[#CURRENT]
        if tab.name and locale ~= GetLocale() then
            return
        end
        tab.name = name
    end

    setfenv(2, {
        C = CreateClass,
        T = CreateTab,
        I = CreateTalentInfo,
        R = FillTalentRanks,
        P = FillTalentPrereq,
        N = SetTabName,
    })
end
