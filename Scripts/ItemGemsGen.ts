/**
 * @File   : ItemGemsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 9/5/2024, 7:10:45 PM
 */

import { ProjectId, WowToolsClient } from './util.ts';

class App {
    private cli: WowToolsClient;

    constructor(projectId: number) {
        this.cli = new WowToolsClient(projectId);
    }

    async run(output: string) {
        const items = await this.cli.fetchTable('ItemSparse');

        items.forEach((item) => {
            item.SocketType = item.SocketType.map((x: string) => Number.parseInt(x) || 0).filter((x: number) => x);
            item.ID = Number.parseInt(item.ID) || 0;
        });
        items.sort((a, b) => a.ID - b.ID);

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

        file.close();
    }
}

async function main() {
    await new App(ProjectId.Wrath).run('Data/Wrath/ItemGemOrder.lua');
    await new App(ProjectId.Cata).run('Data/Cata/ItemGemOrder.lua');
}

main();
