-- .index.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 5/16/2020, 4:26:31 PM

---@class ns
---@field UI UI
---@field Inspect tdInspectInspect

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
