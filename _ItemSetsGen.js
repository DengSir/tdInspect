#!/usr/bin/env node
/**
 * @File   : ItemSetsGen.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 6/3/2021, 3:26:39 PM
 */

const got = require("got");
const util = require("util");
const xmldom = require("xmldom");
const fs = require("fs");

const ITEM_SETS = "https://%s.wowhead.com/item-sets";
const ITEM = "https://%s.wowhead.com/item=%s?xml";

const SLOTS = new Map([
    [0, "INVTYPE_NON_EQUIP"],
    [1, "INVTYPE_HEAD"],
    [2, "INVTYPE_NECK"],
    [3, "INVTYPE_SHOULDER"],
    [4, "INVTYPE_BODY"],
    [5, "INVTYPE_CHEST"],
    [6, "INVTYPE_WAIST"],
    [7, "INVTYPE_LEGS"],
    [8, "INVTYPE_FEET"],
    [9, "INVTYPE_WRIST"],
    [10, "INVTYPE_HAND"],
    [11, "INVTYPE_FINGER"],
    [12, "INVTYPE_TRINKET"],
    [13, "INVTYPE_WEAPON"],
    [14, "INVTYPE_SHIELD"],
    [15, "INVTYPE_RANGED"],
    [16, "INVTYPE_CLOAK"],
    [17, "INVTYPE_2HWEAPON"],
    [18, "INVTYPE_BAG"],
    [19, "INVTYPE_TABARD"],
    [20, "INVTYPE_ROBE"],
    [21, "INVTYPE_WEAPONMAINHAND"],
    [22, "INVTYPE_WEAPONOFFHAND"],
    [23, "INVTYPE_HOLDABLE"],
    [24, "INVTYPE_AMMO"],
    [25, "INVTYPE_THROWN"],
    [26, "INVTYPE_RANGEDRIGHT"],
    [27, "INVTYPE_QUIVER"],
    [28, "INVTYPE_RELIC"],
]);

async function getItemPage(version, itemId) {
    return new xmldom.DOMParser().parseFromString((await got(util.format(ITEM, version, itemId))).body);
}

function getItemBouns(doc) {
    const data = doc.getElementsByTagName("htmlTooltip")[0].childNodes[0].nodeValue;

    return [...data.matchAll(/\((\d+)\)\s*Set\s*:/g)].map(([_, n]) => Number.parseInt(n)).join("/");
}

function getItemSlot(doc) {
    const data = doc.getElementsByTagName("json")[0].childNodes[0].nodeValue;
    const json = JSON.parse(`{${data}}`);
    const slot = json.slot;

    if (!SLOTS.get(slot)) {
        throw Error(`unknown slot id ${json.slot}`);
    }
    return slot;
}

async function genItemSets(version, output) {
    const body = (await got(util.format(ITEM_SETS, version))).body;
    const m = body.match(/var itemSets\s*=\s*([^;]+)/);
    if (m) {
        const itemSets = JSON.parse(m[1])
            .filter(({ pieces }) => pieces)
            .map(({ id, pieces }) => ({ setId: id, items: pieces.sort() }))
            .sort((a, b) => a.setId - b.setId);

        const total = itemSets.length;

        const file = fs.createWriteStream(output);

        console.log(`Generate ${version}`);

        file.write(`---@diagnostic disable: undefined-global
-- GENERATE BY _ItemSetGen.js
select(2,...).ItemSetMake()`);

        let index = 0;

        for (const { setId, items } of itemSets) {
            let bouns;

            file.write(`S(${setId})`);

            for (const itemId of items) {
                const doc = await getItemPage(version, itemId);

                if (!bouns) {
                    bouns = getItemBouns(doc);

                    file.write(`B'${bouns}'`);
                }

                const slot = getItemSlot(doc);

                file.write(`I(${slot},${itemId})`);
            }

            index++;
            console.log(`${index}/${total}`);
        }

        file.end("", "utf-8");
    }
}

async function main() {
    await genItemSets("tbc", "Data/ItemSet.BCC.lua");
    await genItemSets("classic", "Data/ItemSet.lua");
}

main();
