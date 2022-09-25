#!/usr/bin/env node
/**
 * @File   : GlyphGen.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/25 12:39:01
 */

const get = require("./get");

async function main() {
    const r = await get(`https://wow.tools/api/export/?name=glyphproperties&build=3.4.0.45704`);

    console.log(r.body);

    const lines = r.body.split(/[\r\n]+/);

    console.log(lines);
}

main();
