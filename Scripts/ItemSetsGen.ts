/**
 * @File   : ItemSetsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:47:21
 */

import { fetchData } from './util.ts';

interface ProjectData {
    version: string;
    dataEnv: number;
    hasId: boolean;
    hasIcon: boolean;
}
const WOW_TOOLS = 'https://wow.tools/dbc/api/export/';
const PROJECTS: { [key: number]: ProjectData } = {
    [2]: { version: '1.14.3.44834', dataEnv: 4, hasId: false, hasIcon: false },
    [5]: { version: '2.5.4.44833', dataEnv: 5, hasId: true, hasIcon: false },
    [11]: { version: '3.4.0.45770', dataEnv: 8, hasId: true, hasIcon: true },
};
class App {
    private project: ProjectData;

    constructor(projectId: number) {
        this.project = PROJECTS[projectId];
    }

    fetchData(name: string, locale = 'enUS') {
        return fetchData(WOW_TOOLS, { name, locale, build: this.project.version });
    }

    async getItemSetSpells() {
        const csv = await this.fetchData('itemsetspell');
        return csv.map((x) => ({
            setId: Number.parseInt(x[4]),
            threshold: Number.parseInt(x[3]),
        }));
    }

    async getItemSets() {
        const csv = await this.fetchData('itemset');
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
        const csv = await this.fetchData('item');
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
            write('\n');
            write(`B'${i.threshold.join('/')}'`);
            write('\n');

            for (const item of i.items) {
                const slot = itemSlots.get(item);
                if (!slot) {
                    throw Error('not found slot');
                }

                write(`I(${slot},${item})`);
                write('\n');
            }
        }

        file.close();
    }
}

async function main() {
    await new App(11).run('Data/ItemSet.WLK.lua');
}

main();
