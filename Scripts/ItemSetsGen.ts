/**
 * @File   : ItemSetsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:47:21
 */

import { ProjectId, WowToolsClient } from './util.ts';

class App {
    private cli: WowToolsClient;

    constructor(projectId: number) {
        this.cli = new WowToolsClient(projectId);
    }

    async getItemSetSpells() {
        const csv = await this.cli.fetchTable('itemsetspell');
        return csv.map((x) => ({
            setId: Number.parseInt(x[4]),
            threshold: Number.parseInt(x[3]),
        }));
    }

    async getItemSets() {
        const csv = await this.cli.fetchTable('itemset');
        return csv
            .map((x) => ({
                id: Number.parseInt(x[0]),
                items: x
                    .slice(5, 21)
                    .map((x) => Number.parseInt(x))
                    .filter((x) => x)
                    .sort((a, b) => a - b),
            }))
            .filter((x) => x.items.length > 0)
            .sort((a, b) => a.id - b.id);
    }

    async getItemSlots() {
        const csv = await this.cli.fetchTable('item');
        return new Map(csv.map((x) => [Number.parseInt(x[0]), Number.parseInt(x[4])]));
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

        const file = Deno.openSync(output, { write: true, create: true, truncate: true });
        const encoder = new TextEncoder();
        const write = (x: string) => file.writeSync(encoder.encode(x));

        write(`---@diagnostic disable: undefined-global
-- GENERATE BY ItemSetGen.ts
select(2,...).ItemSetMake()`);

        for (const i of data) {
            write(`S(${i.id})`);
            write(`B'${i.threshold.join('/')}'`);

            for (const item of i.items) {
                const slot = itemSlots.get(item);
                if (!slot) {
                    throw Error('not found slot');
                }

                write(`I(${slot},${item})`);
            }
        }

        file.close();
    }
}

async function main() {
    await new App(ProjectId.WLK).run('Data/ItemSet.WLK.lua');
    await new App(ProjectId.Classic).run('Data/ItemSet.lua');
}

main();
