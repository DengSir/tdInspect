/**
 * @File   : GlyphGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 1/28/2024, 4:02:59 PM
 */

import * as path from '@std/path';
import { ProjectId, WowToolsClient } from './util.ts';

class App {
    private cli: WowToolsClient;

    constructor(projectId: number) {
        this.cli = new WowToolsClient(projectId);
    }

    async getGlyphs() {
        const csv = await this.cli.fetchTable('GlyphProperties');
        return csv.map((x) => [
            Number.parseInt(x.ID),
            Number.parseInt(x.SpellID),
            Number.parseInt(x.SpellIconFileDataID),
        ]);
    }

    async run(output: string) {
        Deno.mkdirSync(path.dirname(output), { recursive: true });
        const file = Deno.openSync(output, { write: true, create: true, truncate: true });
        const encoder = new TextEncoder();
        const write = (x: string) => file.writeSync(encoder.encode(x));

        write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY GlyphGen.ts
select(2,...).GlyphMake()`
        );
        write('\n');

        const glyphs = await this.getGlyphs();

        for (const glyph of glyphs) {
            write(`D(${glyph.join(',')})`);
            write('\n');
        }

        file.close();
    }
}

async function main() {
    await new App(ProjectId.Wrath).run('Data/Wrath/Glyph.lua');
    await new App(ProjectId.Cata).run('Data/Cata/Glyph.lua');
}

main();
