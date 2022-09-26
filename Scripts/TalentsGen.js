#!/usr/bin/env node
/**
 * @File   : DataGen.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 5/21/2020, 10:31:02 PM
 */

const fs = require("fs");
const util = require("util");
const get = require("./get");

const LOCALES = [
    [0, "enUS"],
    [1, "koKR"],
    [2, "frFR"],
    [3, "deDE"],
    [4, "zhCN"],
    [5, "zhTW"],
    [6, "esES"],
    [7, "ruRU"],
    [8, "ptBR"],
    [9, "itIT", true],
].filter(([, locale]) => locale);

const PROJECTS = {
    [2]: { version: "1.14.3.44834", dataEnv: 4, hasId: false, hasIcon: false },
    [5]: { version: "2.5.4.44833", dataEnv: 5, hasId: true, hasIcon: false },
    [11]: { version: "3.4.0.45770", dataEnv: 8, hasId: true, hasIcon: true },
};

// const TALENTS = "https://classic.wowhead.com/data/talents-classic";
// const LOCALE = "https://wow.zamimg.com/js/locale/classic.enus.js";
const TALENTS = "https://www.wowhead.com/data/talents-classic?dataEnv=%d";
const LOCALE = "https://nether.wowhead.com/menus?dataEnv=%d";
const GLOBAL = "https://nether.wowhead.com/data/global?dataEnv=%d&locale=%d";
const TALENT_TAB = "https://wow.tools/dbc/api/export/?name=talenttab&build=%s&locale=%s";

function decodeCSV(body, hasHeader = true) {
    const lines = body.split(/[\r\n]+/);
    if (hasHeader) {
        lines.splice(0, 1);
    }
    return lines.map((x) => x.split(","));
}

function getTalentData(body) {
    // const m = body.match(/WH\.Wow\.TalentCalcClassic\.data\s*=\s*({[^;]+});/);
    const m = body.match(/wow\.talentCalcClassic\..+\.data",\s*({[^;]+})\);/);
    const data = JSON.parse(m[1]).talents;
    return data;
}

function getClassTalents(body) {
    const m = body.match(/var mn_spells\s*=(.+);/);

    const d = eval(m[1]);
    const item = d[2][3];

    return item
        .map(([clsId, clsName, , t]) => ({ clsId, clsName, tabs: t.map(([talentId]) => Number.parseInt(talentId)) }))
        .sort((a, b) => a.clsId - b.clsId);
}

class App {
    constructor(projectId) {
        this.projectId = projectId;
        this.version = PROJECTS[projectId].version;
        this.dataEnv = PROJECTS[projectId].dataEnv;
        this.hasId = PROJECTS[projectId].hasId;
        this.hasIcon = PROJECTS[projectId].hasIcon;
    }

    async getTalentLocales(locale) {
        const resp = await get(util.format(GLOBAL, this.dataEnv, locale));
        const body = resp.body;
        const regexes = [
            /WH\.Wow\.PlayerClass\.Specialization\.names', ([^;\)]+)/,
            /wow\.playerClass\.specialization\.names', ([^;\)]+)/,
        ];

        for (const reg of regexes) {
            const m = body.match(reg);

            if (m && m[1]) {
                return JSON.parse(m[1]);
            }
        }
    }

    async getTalentTabInfo(locale) {
        const resp = await get(util.format(TALENT_TAB, this.version, locale));

        const lines = decodeCSV(resp.body);

        return new Map(
            lines.map((x) => [
                Number.parseInt(x[0]),
                {
                    name: x[1],
                    bg: x[2],
                    icon: Number.parseInt(x[7]),
                },
            ])
        );
    }

    async genTalents(output) {
        const version = this.dataEnv;
        const ClassTalents = getClassTalents((await get(util.format(LOCALE, version))).body);

        const Talents = getTalentData((await get(util.format(TALENTS, version))).body);
        const Locales = {};
        let TabInfos;

        for (const [id, locale, wowhead] of LOCALES) {
            if (locale) {
                const d = wowhead ? await this.getTalentLocales(locale) : await this.getTalentTabInfo(locale);

                if (locale == "enUS") {
                    TabInfos = d;
                }

                if (wowhead) {
                    Locales[locale] = d;
                } else {
                    Locales[locale] = Object.fromEntries([...d.entries()].map((x) => [x[0], x[1].name]));
                }
            }
        }

        console.log(`Generate ${output}`);

        const file = fs.createWriteStream(output);

        file.write(`---@diagnostic disable: undefined-global
-- GENERATE BY _TalentGen.js
select(2,...).TalentMake()`);

        const indexes = LOCALES.map(([, locale]) => locale);
        file.write(`D'${indexes.join("/")}'`);

        for (const { clsName, tabs } of ClassTalents) {
            console.log(`For ${clsName}`);

            file.write(`C'${clsName.toUpperCase().replace(/ /g, "")}'`);

            for (const tabId of tabs) {
                const talents = Object.values(Talents[tabId]).sort((a, b) => a.row * 10 + a.col - b.row * 10 - b.col);
                const names = LOCALES.map(([, locale]) => Locales[locale][tabId]).join("/");

                {
                    file.write(`T(${tabId},${talents.length},'${TabInfos.get(tabId).bg}'`);
                    if (this.hasIcon) {
                        file.write(`,${TabInfos.get(tabId).icon}`);
                    }
                    file.write(")");
                }

                file.write(`N'${names}'`);

                for (const talent of talents) {
                    {
                        file.write(`I(${talent.row + 1},${talent.col + 1},${talent.ranks.length}`);
                        if (this.hasId) {
                            file.write(`,${talent.id}`);
                        }
                        file.write(")");
                    }
                    file.write(`R{${talent.ranks.join(",")}}`);

                    if (talent.requires) {
                        for (const req of talent.requires) {
                            const reqTalent = Talents[tabId][req.id];
                            const reqIndex = talents.indexOf(reqTalent) + 1;
                            file.write(`P(${reqTalent.row + 1},${reqTalent.col + 1},${reqIndex})`);
                        }
                    }
                }
            }
        }
        file.end("", "utf-8");
    }
}

async function main() {
    await new App(11).genTalents("Data/Talents.WLK.lua");
    await new App(5).genTalents("Data/Talents.BCC.lua");
    await new App(2).genTalents("Data/Talents.lua");
}

main();
