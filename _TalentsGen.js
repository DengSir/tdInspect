#!/usr/bin/env node
/**
 * @File   : DataGen.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 5/21/2020, 10:31:02 PM
 */

const fs = require("fs");
const got = require("got");
const util = require("util");
// const HttpsProxyAgent = require("hpagent").HttpsProxyAgent;

// function get(url) {
//     return got(url, {
//         agent: {
//             https: new HttpsProxyAgent({
//                 keepAlive: true,
//                 keepAliveMsecs: 1000,
//                 maxSockets: 256,
//                 maxFreeSockets: 256,
//                 scheduling: "lifo",
//                 proxy: "http://localhost:8787",
//             }),
//         },
//     });
// }

const get = got;

const LOCALES = [
    [0, "enUS"],
    [1, "koKR"],
    [2, "frFR"],
    [3, "deDE"],
    [4, "zhCN"],
    [5],
    [6, "esES"],
    [7, "ruRU"],
    [8, "ptBR"],
    [9, "itIT"],
].filter(([, locale]) => locale);

// const TALENTS = "https://classic.wowhead.com/data/talents-classic";
// const LOCALE = "https://wow.zamimg.com/js/locale/classic.enus.js";
const TALENTS = "https://www.wowhead.com/data/talents-classic?dataEnv=%d";
const LOCALE = "https://nether.wowhead.com/menus?dataEnv=%d";
const GLOBAL = "https://nether.wowhead.com/data/global?dataEnv=%d&locale=%d";

function getTalentData(body) {
    // const m = body.match(/WH\.Wow\.TalentCalcClassic\.data\s*=\s*({[^;]+});/);
    const m = body.match(/wow\.talentCalcClassic\..+\.data",\s*({[^;]+})\);/);
    const data = JSON.parse(m[1]).talents;
    return data;
}

// function getClassTalents(body) {
//     const m = body.match(/var mn_spells=(.+);\(function/);

//     for (const item of eval(m[1])) {
//         if (item[1] === "Talents") {
//             return item[3]
//                 .map((t) => [t[1], t[3].map((r) => r[0])])
//                 .reduce((t, v) => {
//                     t[v[0]] = v[1];
//                     return t;
//                 }, {});
//         }
//     }
// }

function getClassTalents(body) {
    const m = body.match(/var mn_spells\s*=(.+);/);

    const d = eval(m[1]);
    const item = d[2][3];

    return item
        .map(([clsId, clsName, , t]) => ({ clsId, clsName, tabs: t.map(([talentId]) => Number.parseInt(talentId)) }))
        .sort((a, b) => a.clsId - b.clsId);
}

// function getTalentLocales(body) {
//     const m = body.match(/var g_chr_specs=({[^;]+});/);
//     return JSON.parse(m[1]);
// }

function getTalentLocales(body) {
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

async function genTalents(version, output, hasId) {
    const ClassTalents = getClassTalents((await get(util.format(LOCALE, version))).body);

    const Talents = getTalentData((await get(util.format(TALENTS, version))).body);
    const Locales = {};

    for (const [id, locale] of LOCALES) {
        if (locale) {
            Locales[locale] = getTalentLocales((await get(util.format(GLOBAL, version, id))).body);
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

            file.write(`T(${tabId},${talents.length})`);
            file.write(`N'${names}'`);

            for (const talent of talents) {
                if (hasId) {
                    file.write(`I(${talent.row + 1},${talent.col + 1},${talent.ranks.length},${talent.id})`);
                } else {
                    file.write(`I(${talent.row + 1},${talent.col + 1},${talent.ranks.length})`);
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

async function main() {
    await genTalents(8, "Data/Talents.WLK.lua", true);
    await genTalents(5, "Data/Talents.BCC.lua", true);
    await genTalents(4, "Data/Talents.lua", false);
}

main();
