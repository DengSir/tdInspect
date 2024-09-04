/**
 * @File   : ItemSetsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:47:21
 */

import * as path from '@std/path';
import { ProjectId, WowToolsClient } from './util.ts';

class App {
    private cli: WowToolsClient;

    constructor(projectId: number) {
        this.cli = new WowToolsClient(projectId);
    }

    async getItemSetSpells() {
        const csv = await this.cli.fetchTable('itemsetspell');
        return csv.map((x) => ({
            setId: Number.parseInt(x.ItemSetID),
            threshold: Number.parseInt(x.Threshold),
        }));
    }

    async getItemSets() {
        const csv = await this.cli.fetchTable('itemset');
        return csv
            .map((x) => ({
                id: Number.parseInt(x.ID),
                items: (x.ItemID as string[])
                    .map((x) => Number.parseInt(x))
                    .filter((x) => x)
                    .sort((a, b) => a - b),
            }))
            .filter((x) => x.items.length > 0)
            .sort((a, b) => a.id - b.id);
    }

    async getItemSlots() {
        const csv = await this.cli.fetchTable('item');
        return new Map(csv.map((x) => [Number.parseInt(x.ID), Number.parseInt(x.InventoryType)]));
    }

    async run(output: string) {
        const itemSets = await this.getItemSets();
        const itemSetSpells = await this.getItemSetSpells();
        const itemSlots = await this.getItemSlots();

        const data = itemSets.map((x) => ({
            ...x,
            threshold: itemSetSpells
                .filter((i) => i.setId == x.id)
                .sort((a, b) => a.threshold - b.threshold)
                .map((i) => i.threshold),
        }));

        Deno.mkdirSync(path.dirname(output), { recursive: true });
        const file = Deno.openSync(output, { write: true, create: true, truncate: true });
        const encoder = new TextEncoder();
        const write = (x: string) => file.writeSync(encoder.encode(x));

        write(`---@diagnostic disable: undefined-global
-- GENERATE BY ItemSetGen.ts
select(2,...).ItemSetMake()`);

        write('\n');

        for (const i of data) {
            write(`S(${i.id})`);
            write(`B'${i.threshold.join('/')}'`);

            for (const item of i.items) {
                let slot = itemSlots.get(item);
                if (!slot) {
                    throw Error('not found slot');
                }

                if (slot === 20) {
                    slot = 5;
                }

                write(`I(${slot},${item})`);
            }
            write('\n');
        }

        file.close();
    }
}

async function main() {
    await new App(ProjectId.Wrath).run('Data/Wrath/ItemSet.lua');
    await new App(ProjectId.Vanilla).run('Data/Vanilla/ItemSet.lua');
    await new App(ProjectId.Cata).run('Data/Cata/ItemSet.lua');
}

main();
