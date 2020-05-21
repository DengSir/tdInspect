#!/usr/bin/env node
/**
 * @File   : DataGen.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 5/21/2020, 10:31:02 PM
 */

const fs = require("fs");
const got = require("got");
const json2lua = require("json2lua");

const LOCALES = ["deDE", "esES", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN"];

const TALENTS = "https://classic.wowhead.com/data/talents-classic";
const LOCALE = "https://wow.zamimg.com/js/locale/classic.enus.js";

const BACKGROUNDS = {
    ["283"]: "DruidBalance",
    ["281"]: "DruidFeralCombat",
    ["282"]: "DruidRestoration",
    ["361"]: "HunterBeastMastery",
    ["363"]: "HunterMarksmanship",
    ["362"]: "HunterSurvival",
    ["81"]: "MageArcane",
    ["41"]: "MageFire",
    ["61"]: "MageFrost",
    ["382"]: "PaladinHoly",
    ["383"]: "PaladinProtection",
    ["381"]: "PaladinCombat",
    ["201"]: "PriestDiscipline",
    ["202"]: "PriestHoly",
    ["203"]: "PriestShadow",
    ["182"]: "RogueAssassination",
    ["181"]: "RogueCombat",
    ["183"]: "RogueSubtlety",
    ["261"]: "ShamanElementalCombat",
    ["263"]: "ShamanEnhancement",
    ["262"]: "ShamanRestoration",
    ["302"]: "WarlockCurses",
    ["303"]: "WarlockSummoning",
    ["301"]: "WarlockDestruction",
    ["161"]: "WarriorArms",
    ["164"]: "WarriorFury",
    ["163"]: "WarriorProtection",
};

function getTalentData(body) {
    const m = body.match(/WH\.Wow\.TalentCalcClassic\.data=({[^;]+});/);
    const data = JSON.parse(m[1]).talents;
    return data;
}

function getClassTalents(body) {
    const m = body.match(/var mn_spells=(.+);\(function/);

    for (const item of eval(m[1])) {
        if (item[1] === "Talents") {
            return item[3]
                .map((t) => [t[1], t[3].map((r) => r[0])])
                .reduce((t, v) => {
                    t[v[0]] = v[1];
                    return t;
                }, {});
        }
    }
}

function getTalentLocales(body) {
    const m = body.match(/var g_chr_specs=({[^;]+});/);
    return JSON.parse(m[1]);
}

async function main() {
    const enUS = (await got(LOCALE)).body;
    const ClassTalents = getClassTalents(enUS);
    const Talents = getTalentData((await got(TALENTS)).body);
    const Locales = getTalentLocales(enUS);

    const result = {};

    for (const [key, value] of Object.entries(ClassTalents)) {
        result[key.toUpperCase()] = value.map((talentId) => {
            const talents = Object.values(Talents[talentId]);
            return {
                name: Locales[talentId],
                background: BACKGROUNDS[talentId],
                numTalents: talents.length,
                talents: talents
                    .sort((a, b) => a.row * 10 + a.col - b.row * 10 - b.col)
                    .map((item) => ({
                        row: item.row + 1,
                        column: item.col + 1,
                        maxRank: item.ranks.length,
                        ranks: item.ranks,
                        prereqs:
                            item.requires.length === 0
                                ? undefined
                                : item.requires.map((req) => ({
                                      row: Talents[talentId][req.id].row + 1,
                                      column: Talents[talentId][req.id].col + 1,
                                  })),
                    })),
            };
        });
    }

    fs.writeFileSync(
        "Data/Talents.lua",
        "---@type ns\nlocal ns = select(2, ...)\nns.Talents=" + json2lua.fromString(JSON.stringify(result))
    );

    const lines = [];
    lines.push("---@type ns");
    lines.push("local ns = select(2, ...)");
    lines.push("local talent");

    for (const locale of LOCALES) {
        const locales = getTalentLocales(
            (await got(`https://wow.zamimg.com/js/locale/classic.${locale.toLowerCase()}.js`)).body
        );

        lines.push(`if GetLocale() == '${locale}' then`);

        for (const [key, value] of Object.entries(ClassTalents)) {
            lines.push(`    talent = ns.Talents.${key.toUpperCase()}`);
            for (const [i, talentId] of value.entries()) {
                lines.push(`    talent[${i + 1}].name = '${locales[talentId]}'`);
            }
        }

        lines.push("end");
        lines.push("");
    }

    fs.writeFileSync("Data/Locales.lua", lines.join("\n"));
}

main();
