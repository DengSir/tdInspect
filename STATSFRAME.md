# StatsFrame 装备加成面板 — 开发计划与完成情况

## 计划目标

在 `CharacterGearFrame` 和 `InspectGearFrame` 右侧各添加一个 `UI.StatsFrame` 面板，
展示纯装备链接可推导的加成信息：宝石、属性统计、套装激活状态。

---

## 完成情况

| # | 文件 | 内容 | 状态 |
|---|------|------|------|
| 1 | `UI/StatsFrame.lua` | 核心 UI 类：ScrollFrame 布局、宝石区、属性区、套装区 | ✅ |
| 2 | `tdInspect.toc` | 新增 `UI\StatsFrame.lua` 加载条目 | ✅ |
| 3 | `Addon.lua` | `GetCharacterStatsFrame` / `GetInspectStatsFrame` 懒加载；`OpenCharacterGearFrame` / `OpenInspectGearFrame` 显示/定位 StatsFrame | ✅ |
| 4 | `UI/CharacterGearFrame.lua` | `OnHide` 联动隐藏；`UNIT_INVENTORY_CHANGED` 联动 `Refresh` | ✅ |
| 5 | `UI/InspectGearFrame.lua` | `OnHide` 联动隐藏；`Update` 末尾联动 `Refresh` | ✅ |
| 6 | `Localization/enUS.lua` | 新增 `Gear Bonuses` / `Gems` / `Stats` / `Set Bonuses` / `pieces` 等 key | ✅ |
| 7 | `Localization/zhCN.lua` | 对应中文翻译 | ✅ |

---

## 面板展示内容（最终版）

### 宝石区

- 按 subClassId 排序，相同宝石合并计数
- 格式：`[彩色圆点] 品质色名称 xN`

### 属性区（`GetItemStats` 聚合）

- 来源：已装备宝石 + item 类型附魔（有 `itemId` 的）
- 格式：`属性名   +数值`

### 套装加成区

- 格式：`套装名 (N/M件)` + 各阈值行，激活绿色 / 未激活灰色

---

## 布局逻辑

| 场景 | 布局 |
|------|------|
| 角色面板 | `[PaperDoll] \| [CharacterGearFrame] \| [CharacterStatsFrame]` |
| 纯观察 | `[InspectPaperDoll] \| [InspectGearFrame] \| [InspectStatsFrame]` |
| 观察+比较 | `[InspectPaperDoll] \| [InspectGearFrame] \| [CharacterGearFrame] \| [CharacterStatsFrame]`（InspectStatsFrame 隐藏） |

---

## 已知局限

- `GetItemStats` 仅支持 item 类型附魔（有 `itemId`），spell 类型附魔（`spellId`）无属性数据，暂不统计
- `GetItemInfo` 异步，首次打开时宝石名称可能显示为 `Item:xxxxx`，后续 `UNIT_INVENTORY_CHANGED` 触发 Refresh 后自动更新
