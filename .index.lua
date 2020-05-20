-- .index.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/16/2020, 4:26:31 PM

---@class ns
---@field UI UI
---@field Inspect tdInspectInspect
---@field Talent tdInspectTalent
---@field Talents table<string, tdInspectTalentTab[]>

---@class UI
---@field BaseItem tdInspectBaseItem
---@field EquipFrame tdInspectEquipFrame
---@field ModalFrame tdInspectModalFrame
---@field EquipItem tdInspectEquipItem
---@field SlotItem tdInspectSlotItem
---@field PaperDoll tdInspectPaperDoll
---@field InspectFrame tdInspectInspectFrame

---@class tdInspectInspect

---@class tdInspectEquipFrame: Frame

---@class tdInspectEquipItem: tdInspectBaseItem

---@class tdInspectModalFrame: Frame

---@class tdInspectPaperDoll: Frame
---@field private buttons tdInspectSlotItem[]

---@class tdInspectSlotItem: tdInspectBaseItem
---@field private IconBorder Texture

---@class tdInspectInspectFrame: Frame

---@class tdInspectBaseItem: Button

---@class tdInspectInspectTalentFrame: tdInspectTalentFrame

---@class tdInspectTalentFrame: Frame

---@class tdInspectTalentPrereqs
---@field row number
---@field column number

---@class tdInspectTalentItemInfo
---@field name string
---@field tips string
---@field row number
---@field column number
---@field icon number
---@field ranks number
---@field tipValues any
---@field prereqs tdInspectTalentPrereqs[]

---@class tdInspectTalentItem
---@field info tdInspectTalentItemInfo

---@class tdInspectTalentTab
---@field numtalents number
---@field talents tdInspectTalentItem[]
---@field info tdInspectTalentTabInfo

---@class tdInspectTalentTabInfo
---@field name string
---@field background string

---@class tdInspectTalentBranch
---@field id number
---@field up number
---@field down number
---@field left number
---@field right number
---@field rightArrow number
---@field leftArrow number
---@field topArrow number
