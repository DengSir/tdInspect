-- StatsFrame.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 4/29/2026, 12:00:00 PM
--
---@type ns
local ns = select(2, ...)

local L = ns.L
local GetItemInfo = GetItemInfo
local GetItemInfoInstant = GetItemInfoInstant
local GetItemSetInfo = GetItemSetInfo
local tinsert = table.insert
local wipe = wipe
local pairs = pairs
local ipairs = ipairs
local math = math

-- Enum.ItemGemSubclass value → display color {r,g,b}
local GEM_COLORS = {
    [0] = {0.6, 0.6, 0.6}, -- Meta
    [1] = {1,   0.2, 0.2}, -- Red
    [2] = {0.2, 0.6, 1  }, -- Blue
    [3] = {1,   1,   0  }, -- Yellow
    [4] = {0.8, 0.2, 1  }, -- Purple
    [5] = {0,   0.8, 0.3}, -- Green
    [6] = {1,   0.5, 0  }, -- Orange
    [7] = {1,   1,   1  }, -- Prismatic
}

local ROW_HEIGHT    = 16
local ROW_SPACING   = 2
local SECTION_PAD   = 8
local SIDE_PAD      = 8
local FRAME_WIDTH   = 230

---@class UI.StatsFrame : Frame, BackdropTemplate, EventHandler
local StatsFrame = ns.Addon:NewClass('UI.StatsFrame', 'Frame')

function StatsFrame:Create(parent)
    local f = CreateFrame('Frame', nil, parent, 'BackdropTemplate')
    f:SetBackdrop{
        bgFile   = [[Interface\Tooltips\UI-Tooltip-Background]],
        edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
        tile     = true,
        tileSize = 8,
        edgeSize = 16,
        insets   = {left = 4, right = 4, top = 4, bottom = 4},
    }
    f:SetBackdropColor(0, 0, 0, 0.95)
    f:SetWidth(FRAME_WIDTH)
    return self:Bind(f)
end

function StatsFrame:Constructor()
    self:Hide()
    self:EnableMouse(true)

    local title = self:CreateFontString(nil, 'ARTWORK', 'GameFontNormalOutline')
    title:SetPoint('TOPLEFT', SIDE_PAD, -8)
    title:SetTextColor(1, 0.82, 0)
    title:SetText(L['Gear Bonuses'])
    self.Title = title

    local sf = CreateFrame('ScrollFrame', nil, self, 'UIPanelScrollFrameTemplate')
    sf:SetPoint('TOPLEFT',     SIDE_PAD, -26)
    sf:SetPoint('BOTTOMRIGHT', -26,       8)
    self.ScrollFrame = sf

    local content = CreateFrame('Frame', nil, sf)
    content:SetPoint('TOPLEFT')
    content:SetSize(FRAME_WIDTH - SIDE_PAD - 26, 400)
    sf:SetScrollChild(content)
    self.Content = content

    -- pool of reusable FontStrings and Textures
    self.fsPool  = {}
    self.texPool = {}
    self.usedFs  = {}
    self.usedTex = {}
end

function StatsFrame:SetGetItemLink(fn)
    self.getItemLink = fn
end

function StatsFrame:TapTo(frame, position)
    self:SetParent(frame)
    self:ClearAllPoints()
    if position == 'TOPRIGHT' then
        self:SetPoint('TOPLEFT', frame, 'TOPRIGHT')
    elseif position == 'TOPLEFT' then
        self:SetPoint('TOPLEFT', frame, 'TOPLEFT')
    end
    self:SetHeight(frame:GetHeight())
end

-- Acquire/release FontString pool
local function AcquireFS(self, template)
    local fs = table.remove(self.fsPool)
    if not fs then
        fs = self.Content:CreateFontString(nil, 'ARTWORK', template or 'GameFontHighlightSmall')
    end
    fs:SetFontObject(template or 'GameFontHighlightSmall')
    fs:Show()
    tinsert(self.usedFs, fs)
    return fs
end

local function AcquireTex(self)
    local tex = table.remove(self.texPool)
    if not tex then
        tex = self.Content:CreateTexture(nil, 'ARTWORK')
    end
    tex:Show()
    tinsert(self.usedTex, tex)
    return tex
end

local function ReleaseAll(self)
    for _, fs in ipairs(self.usedFs) do
        fs:Hide()
        fs:ClearAllPoints()
        tinsert(self.fsPool, fs)
    end
    wipe(self.usedFs)
    for _, tex in ipairs(self.usedTex) do
        tex:Hide()
        tex:ClearAllPoints()
        tinsert(self.texPool, tex)
    end
    wipe(self.usedTex)
end

function StatsFrame:Refresh()
    if not self.getItemLink then
        return
    end

    ReleaseAll(self)

    local content = self.Content
    local sf = self.ScrollFrame
    local contentWidth = sf:GetWidth()
    if contentWidth > 0 then
        content:SetWidth(contentWidth)
    end
    local y = -4

    -- ── helpers ──────────────────────────────────────────────────────────────

    local function AddSectionHeader(text)
        y = y - SECTION_PAD

        local fs = AcquireFS(self, 'GameFontNormal')
        fs:SetPoint('TOPLEFT', content, 'TOPLEFT', SIDE_PAD / 2, y)
        fs:SetText(text)
        fs:SetTextColor(1, 0.82, 0)

        local line = AcquireTex(self)
        line:SetPoint('TOPLEFT',  content, 'TOPLEFT',  SIDE_PAD / 2, y - ROW_HEIGHT)
        line:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -SIDE_PAD / 2, y - ROW_HEIGHT)
        line:SetHeight(1)
        line:SetColorTexture(1, 0.82, 0, 0.35)

        y = y - ROW_HEIGHT - ROW_SPACING - 3
    end

    local function AddRow(label, value, lr, lg, lb, vr, vg, vb)
        local lfs = AcquireFS(self)
        lfs:SetPoint('TOPLEFT', content, 'TOPLEFT', SIDE_PAD / 2, y)
        lfs:SetText(label)
        if lr then lfs:SetTextColor(lr, lg, lb) end

        if value then
            local vfs = AcquireFS(self)
            vfs:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -SIDE_PAD / 2, y)
            vfs:SetText(value)
            vfs:SetJustifyH('RIGHT')
            if vr then vfs:SetTextColor(vr, vg, vb) end
        end

        y = y - ROW_HEIGHT - ROW_SPACING
    end

    local function AddGemRow(subClassId, gemName, quality, count)
        local c = GEM_COLORS[subClassId] or {0.7, 0.7, 0.7}

        local dot = AcquireTex(self)
        dot:SetPoint('TOPLEFT', content, 'TOPLEFT', SIDE_PAD / 2, y - (ROW_HEIGHT - 8) / 2)
        dot:SetSize(8, 8)
        dot:SetColorTexture(c[1], c[2], c[3], 1)

        local fs = AcquireFS(self)
        fs:SetPoint('TOPLEFT', content, 'TOPLEFT', SIDE_PAD / 2 + 12, y)
        local displayText = count > 1 and (gemName .. ' x' .. count) or gemName
        fs:SetText(displayText)
        if quality and quality >= 0 then
            local r, g, b = GetItemQualityColor(quality)
            if r then fs:SetTextColor(r, g, b) end
        end

        y = y - ROW_HEIGHT - ROW_SPACING
    end

    -- ── Data collection ───────────────────────────────────────────────────────

    local gemCounts   = {} -- gemId -> count
    local gemSubClass = {} -- gemId -> subClassId
    local gemOrder    = {} -- unique gemIds in insertion order
    local totalStats  = {} -- statKey -> accumulated value

    -- Gems
    if ns.BUILD >= 2 then
        for slot = 1, 18 do
            local link = self.getItemLink(slot)
            if link then
                for _, gemId in ipairs(ns.GetItemGems(link)) do
                    if gemId and gemId ~= 0 then
                        local classId, subClassId = select(6, GetItemInfoInstant(gemId))
                        if classId == Enum.ItemClass.Gem then
                            if not gemCounts[gemId] then
                                tinsert(gemOrder, gemId)
                                gemSubClass[gemId] = subClassId
                                gemCounts[gemId] = 0
                            end
                            gemCounts[gemId] = gemCounts[gemId] + 1
                        end
                    end
                end
            end
        end

    end

    -- Item stats (base stats only, via full item link)
    if GetItemStats then
        for slot = 1, 18 do
            local link = self.getItemLink(slot)
            if link then
                local itemStats = {}
                if GetItemStats(link, itemStats) then
                    for stat, val in pairs(itemStats) do
                        totalStats[stat] = (totalStats[stat] or 0) + val
                    end
                end
            end
        end
    end

    -- Gem stats (each unique gem × count)
    if GetItemStats then
        for _, gemId in ipairs(gemOrder) do
            local _, gemLink = GetItemInfo(gemId)
            if gemLink then
                local gemStats = {}
                if GetItemStats(gemLink, gemStats) then
                    local count = gemCounts[gemId]
                    for stat, val in pairs(gemStats) do
                        totalStats[stat] = (totalStats[stat] or 0) + val * count
                    end
                end
            end
        end
    end

    -- Enchant stats (item-type enchants only)
    if GetItemStats then
        for slot = 1, 18 do
            local link = self.getItemLink(slot)
            if link then
                local enchant = ns.GetItemEnchantInfo(link)
                if enchant and enchant.itemId then
                    local _, enchantLink = GetItemInfo(enchant.itemId)
                    if enchantLink then
                        local enchantStats = {}
                        if GetItemStats(enchantLink, enchantStats) then
                            for stat, val in pairs(enchantStats) do
                                totalStats[stat] = (totalStats[stat] or 0) + val
                            end
                        end
                    end
                end
            end
        end
    end

    -- Set bonus data
    local setCounts = {}
    for slot = 1, 18 do
        local link = self.getItemLink(slot)
        if link then
            local setId = select(16, GetItemInfo(link))
            if setId and setId ~= 0 then
                setCounts[setId] = (setCounts[setId] or 0) + 1
            end
        end
    end

    -- ── Section 1: Gems ───────────────────────────────────────────────────────
    if #gemOrder > 0 then
        table.sort(gemOrder, function(a, b)
            return (gemSubClass[a] or 99) < (gemSubClass[b] or 99)
        end)

        AddSectionHeader(L['Gems'])
        for _, gemId in ipairs(gemOrder) do
            local name, _, quality = GetItemInfo(gemId)
            name = name or ('Item:' .. gemId)
            AddGemRow(gemSubClass[gemId], name, quality, gemCounts[gemId])
        end
    end

    -- ── Section 2: Stats (gems + enchants) ────────────────────────────────────
    if next(totalStats) then
        AddSectionHeader(L['Stats'])
        local statList = {}
        for stat, val in pairs(totalStats) do
            tinsert(statList, {stat = stat, val = val})
        end
        table.sort(statList, function(a, b) return a.stat < b.stat end)
        for _, entry in ipairs(statList) do
            local statName = _G[entry.stat] or entry.stat
            AddRow(statName, '+' .. entry.val)
        end
    end

    -- ── Section 3: Set Bonuses ────────────────────────────────────────────────
    if next(setCounts) then
        AddSectionHeader(L['Set Bonuses'])
        for setId, count in pairs(setCounts) do
            local setName = GetItemSetInfo(setId) or tostring(setId)
            local setData = ns.ItemSets and ns.ItemSets[setId]
            local maxPieces = setData and #setData.slots or count

            AddRow(setName .. ' (' .. count .. '/' .. maxPieces .. L['pieces'] .. ')',
                   nil, 1, 1, 1)

            if setData and setData.bouns then
                for _, threshold in ipairs(setData.bouns) do
                    if count >= threshold then
                        AddRow('  ' .. threshold .. L['pieces'], nil, 0, 1, 0)
                    else
                        AddRow('  ' .. threshold .. L['pieces'], nil, 0.5, 0.5, 0.5)
                    end
                end
            end
        end
    end

    -- ── Finalize content height ───────────────────────────────────────────────
    content:SetHeight(math.abs(y) + 8)
    self.ScrollFrame:UpdateScrollChildRect()
end
