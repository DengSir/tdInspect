-- .index.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/16/2020, 4:26:31 PM

---@class ns
---@field UI UI
---@field Inspect tdInspectInspect
---@field Talent tdInspectTalent
---@field Talents table<string, tdInspectDataTalentTabInfo[]>

---@class UI
---@field BaseItem tdInspectBaseItem
---@field EquipFrame tdInspectEquipFrame
---@field ModalFrame tdInspectModalFrame
---@field EquipItem tdInspectEquipItem
---@field SlotItem tdInspectSlotItem
---@field PaperDoll tdInspectPaperDoll
---@field InspectFrame tdInspectInspectFrame

---@class tdInspectAddon
---@field InspectFrame tdInspectInspectTalentFrame

---@class tdInspectInspect

---@class tdInspectEquipFrame: Frame

---@class tdInspectEquipItem: tdInspectBaseItem

---@class tdInspectModalFrame: Frame

---@class tdInspectPaperDoll: Frame
---@field private buttons tdInspectSlotItem[]

---@class tdInspectSlotItem: tdInspectBaseItem
---@field private IconBorder Texture

---@class tdInspectInspectFrame: Frame
---@field Portrait Texture

---@class tdInspectBaseItem: Button

---@class tdInspectInspectTalentFrame: tdInspectTalentFrame

---@class tdInspectTalentFrame: Frame

---@class tdInspectTalent

---@class tdInspectTalentBranch
---@field id number
---@field up number
---@field down number
---@field left number
---@field right number
---@field rightArrow number
---@field leftArrow number
---@field topArrow number

---@class tdInspectDataTalentTabInfo
---@field name string
---@field background string
---@field numTalents number
---@field talents tdInspectDataTalentInfo[]

---@class tdInspectDataTalentInfo
---@field name string
---@field icon number
---@field row number
---@field column number
---@field ranks number[]
---@field maxRank number
---@field prereqs tdInspectDataPrereqInfo[]

---@class tdInspectDataPrereqInfo
---@field row number
---@field column number
