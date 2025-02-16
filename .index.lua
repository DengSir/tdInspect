-- .index.lua
-- @Author : Dencer (tdaddon@163.com)
-- @Link   : https://dengsir.github.io
-- @Date   : 1/21/2025, 5:05:17 PM
--
local AceEvent = LibStub('AceEvent-3.0')

---@class EventHandler
local EventHandler = {}
EventHandler.Event = AceEvent.RegisterEvent
EventHandler.UnEvent = AceEvent.UnregisterEvent
EventHandler.UnAllEvents = AceEvent.UnregisterAllEvents
