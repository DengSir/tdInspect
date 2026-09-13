[![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/DengSir/tdInspect/publish.yml?label=Publish)](https://github.com/DengSir/tdInspect/actions/workflows/publish.yml)
[![GitHub Release](https://img.shields.io/github/v/release/DengSir/tdInspect?label=Release)](https://github.com/DengSir/tdInspect/releases)
[![CurseForge Downloads](https://img.shields.io/curseforge/dt/500065?label=Curse%20downloads)](https://www.curseforge.com/wow/addons/tdinspect)

# tdInspect — Remote Inspect

Remote inspect for **WoW Classic**: view any player's gear, talents and glyphs from anywhere, in a UI that looks and feels like Blizzard's own.

[English](#features) | [简体中文](#功能)

![Preview](https://github.com/user-attachments/assets/90e21cdd-c577-4d99-9a67-1f7dc04338bd)

## Features

### Remote inspect
- View the gear, talents and glyphs of players anywhere in the world — raid members, chat names, guild mates — not only those standing next to you
- The normal Inspect action keeps working: in range it uses Blizzard data, otherwise it falls back to remote data (if the target also runs tdInspect or alaTalentEmu) or to the last cached result
- Each panel shows the data source (tdInspect / TalentEmu / Blizzard) and when it was last updated

### Gear list
- A compact gear list opens beside the Character and Inspect frames, with gems, enchants and runes shown inline
- Missing enchants and empty sockets are highlighted — on your own gear, blacksmith extra sockets and ring enchants are reminded as well; ranged weapon enchant warnings default to hunters only
- Average and per-slot item level, with configurable color styles
- While inspecting, your gear list and the target's are shown side by side for comparison

### Talents, specs & glyphs
- Blizzard-style talent frame with both specs and main/secondary marks
- Glyph frame on WotLK, rune support on Classic Era
- From your gear list: click the inactive talent to switch specs; right-click a talent to bind it to an Equipment Set, and switching specs then equips it automatically
- Name your specs with aliases

### Your other characters
- Click the portrait at the top of the gear list to browse gear and talents of your other characters — across realms

### UI & compatibility
- Builds on the default UI, with full ElvUI skin support
- Tooltip fixes: set bonuses count the pieces actually equipped, meta gem and rune tooltips corrected
- Options panel with built-in help: Game Menu → Options → AddOns → tdInspect

Supported clients: **Classic Era (Vanilla)** · **Burning Crusade Classic** · **Wrath of the Lich King Classic**

## Getting started

- Install from [CurseForge](https://www.curseforge.com/wow/addons/tdinspect), or download a [GitHub release](https://github.com/DengSir/tdInspect/releases) and extract it into your `Interface/AddOns` folder
- Right-click a player name in chat, friends, guild, raid, etc. and choose **Inspect** — unit frame menus work too
- Or set the **Inspect target** / **Inspect mouseover** keybindings in the options panel
- **SHIFT+click** a talent, gem, enchant, glyph or item to link it in chat

## FAQ

**Why can't some players be inspected?**
Remote inspection needs the target player to also run tdInspect or alaTalentEmu. Otherwise the standard Blizzard rules apply — the target must be nearby and alive, and you must be out of combat. Data from previous inspections is still available from cache.

**The right-click menu has no Inspect entry.**
Try disabling other addons that modify the player right-click menu.

---

# 中文说明

tdInspect 是 **魔兽世界怀旧服** 的远程观察插件：无视距离查看任意玩家的装备、天赋与雕文，界面沿用暴雪原生风格。

## 功能

### 远程观察
- 观察世界任意角落的玩家 —— 团队成员、聊天栏名字、公会会员，而不只是身边的人
- 原生观察流程无缝增强：距离够近时使用暴雪数据，否则自动回退到远程数据（对方也安装 tdInspect 或 alaTalentEmu 时）或缓存数据
- 面板会显示数据来源（tdInspect / TalentEmu / 暴雪）及最后更新时间

### 装备列表
- 角色面板与观察面板旁打开精简装备列表，内联显示宝石、附魔与符文
- 高亮缺失附魔与空插槽 —— 自己的装备还会提示锻造打孔与戒指附魔；默认仅对猎人提示远程武器附魔缺失
- 显示平均与单件装等，颜色风格可配置
- 观察他人时，双方装备列表并排显示，方便对比

### 天赋与雕文
- 暴雪风格天赋面板，支持双天赋并标记主/副
- 巫妖王之怒显示雕文面板，经典旧世支持符文
- 装备列表中：点击非当前天赋可直接切换天赋；右键天赋可绑定套装，之后切天赋自动换装
- 天赋可设置别名

### 我的其它角色
- 点击装备列表顶部的头像，即可浏览其它角色的装备与天赋 —— 支持跨服务器

### 界面与兼容
- 基于并增强原生 UI，完整支持 ElvUI 皮肤
- 鼠标提示修复：套装加成按实际装备件数显示、修正多彩宝石与符文提示
- 设置面板自带帮助：游戏菜单 → 选项 → 插件 → tdInspect

支持版本：**经典怀旧服（60）** · **燃烧的远征** · **巫妖王之怒**

## 使用方法

- 从 [CurseForge](https://www.curseforge.com/wow/addons/tdinspect) 安装，或下载 [GitHub Release](https://github.com/DengSir/tdInspect/releases) 解压到 `Interface/AddOns` 目录
- 在聊天、好友、公会、团队等右键菜单中选择**观察**，单位框体菜单同样可用
- 也可在设置面板中绑定**观察目标** / **观察鼠标悬停目标**快捷键
- **SHIFT+点击**天赋、宝石、附魔、雕文或装备可插入聊天链接

## 常见问题

**为什么有些玩家观察不了？**
远程观察需要对方也安装 tdInspect 或 alaTalentEmu。否则遵循暴雪原生规则 —— 目标必须在附近且存活，且自己不在战斗中。之前观察过的数据仍可从缓存查看。

**右键菜单里没有观察选项？**
尝试禁用其它修改玩家右键菜单的插件。

---

Author: Dencer · License: [MIT](LICENSE.md)
