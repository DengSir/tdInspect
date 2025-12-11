/**
 * @File   : GlyphGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 1/28/2024, 4:02:59 PM
 */

import { FileIo, ProjectId, WowToolsClient } from './util.ts';

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
        const io = new FileIo(output);
        io.write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY GlyphGen.ts
select(2,...).GlyphMake()
`);

        const glyphs = await this.getGlyphs();

        for (const glyph of glyphs) {
            io.write(`D(${glyph.join(',')})\n`);
        }

        io.close();
    }
}

async function main() {
    await new App(ProjectId.Wrath).run('Data/Wrath/Glyph.lua');
    await new App(ProjectId.Mists).run('Data/Mists/Glyph.lua');
}

main();
