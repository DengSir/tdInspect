---@meta
---@class tdInspectPortraitTemplate : Frame
---@field PortraitRing Texture
---@field Portrait Texture
---@field PortraitRingQuality Texture
---@field LevelBorder Texture
---@field Level FontString
---@field PortraitRingCover Texture
local tdInspectPortraitTemplate = {}

---@class tdInspectGearTalentTemplate : Button
---@field Icon Texture
---@field CircleMask MaskTexture
---@field Text FontString
---@field Point FontString
local tdInspectGearTalentTemplate = {}

---@class __tdInspectGearFrameTemplate_Portrait : tdInspectPortraitTemplate , Frame

---@class __tdInspectGearFrameTemplate_Talent1 : tdInspectGearTalentTemplate , Button

---@class __tdInspectGearFrameTemplate_Talent2 : tdInspectGearTalentTemplate , Button

---@class tdInspectGearFrameTemplate : BackdropTemplate , Frame
---@field Name FontString
---@field ItemLevel FontString
---@field TopLeft Texture
---@field TopRight Texture
---@field BottomLeft Texture
---@field BottomRight Texture
---@field Portrait __tdInspectGearFrameTemplate_Portrait
---@field Talent1 __tdInspectGearFrameTemplate_Talent1
---@field Talent2 __tdInspectGearFrameTemplate_Talent2
local tdInspectGearFrameTemplate = {}

---@class tdInspectSocketItemTemplate : Button
---@field Icon Texture
---@field Border Texture
---@field CircleMask MaskTexture
local tdInspectSocketItemTemplate = {}
