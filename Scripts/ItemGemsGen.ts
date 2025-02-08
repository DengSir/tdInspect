/**
 * @File   : ItemGemsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 9/5/2024, 7:10:45 PM
 */

import { ProjectId, WowToolsClient } from './util.ts';

class App {
    private cli: WowToolsClient;

    constructor(private projectId: number) {
        this.cli = new WowToolsClient(projectId);
    }

    async run(output: string) {
        const items = await this.cli.fetchTable('ItemSparse');

        items.forEach((item) => {
            item.SocketType = item.SocketType.map((x: string) => Number.parseInt(x) || 0).filter((x: number) => x);
            item.ID = Number.parseInt(item.ID) || 0;
        });
        items.sort((a, b) => a.ID - b.ID);

        const itemsExists = new Set(items.map((x) => x.ID));


        console.log(output);
        const file = Deno.openSync(output, { write: true, create: true, truncate: true });
        const encoder = new TextEncoder();
        const write = (x: string) => file.writeSync(encoder.encode(x));

        write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY ItemGem.ts
select(2,...).ItemGemOrderMake()
`
        );

        for (const item of items.filter((x) => x.SocketType.length > 0)) {
            write(`D(${item.ID},${item.SocketType.join(',')})\n`);
        }

        if (this.projectId === ProjectId.Wrath) {
            try {
                const items2 = ((await (await fetch('https://dengsir.github.io/wotlk/assets/database/db.json')).json())
                    .items as any[])
                    .filter(x => !itemsExists.has(x.id))
                    .filter(x => x.gemSockets && x.gemSockets.length > 0)
                    .sort((a, b) => a.id - b.id);

                for (const item of items2) {
                    write(`D(${item.id},${item.gemSockets.map(x => (x === 3 ? 4 : x == 4 ? 3 : x).toString()).join(',')})\n`);
                }
            } catch {
                console.log('error');
            }
        }

        file.close();
    }
}

async function main() {
    await new App(ProjectId.Wrath).run('Data/Wrath/ItemGemOrder.lua');
    await new App(ProjectId.Cata).run('Data/Cata/ItemGemOrder.lua');
}

main();
