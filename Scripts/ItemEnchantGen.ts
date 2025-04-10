/**
 * @File   : ItemEnchantGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 9/4/2024, 2:23:31 PM
 */

import { ProjectId } from "./util.ts";

interface ItemEnchant {
    isTemporary: boolean;
    enchant: number;
    spell: number;
    requiredItemClass: number;
    item?: number;
    itemSubclassMask?: number;
    invTypeMask?: number;
}

interface ItemEnchantMap {
    [key: string]: ItemEnchant;
}

class App {
    private url: string;

    constructor(projectId: ProjectId) {
        if (projectId === ProjectId.Wrath) {
            this.url = 'https://nether.wowhead.com/wotlk/data/gear-planner?dv=100';
        } else if (projectId === ProjectId.Vanilla) {
            this.url = 'https://nether.wowhead.com/classic/data/gear-planner?dv=100';
        } else {
            throw new Error('not support');
        }
    }

    async run(file: string) {
        const resp = await fetch(this.url);
        const text = await resp.text();

        const m = text.match(/"wow\.gearPlanner\.\w+.enchant",(.+)\)/);
        if (!m) {
            throw Error('not found');
        }
        const d = JSON.parse(m[1]) as ItemEnchantMap | undefined;

        if (!d) {
            throw Error('not found');
        }

        const codes = [];
        const enchants = Object.entries(d).sort((a, b) => a[1].enchant - b[1].enchant);

        for (const [, v] of enchants) {
            if (v.isTemporary) {
                continue;
            }
            if (v.requiredItemClass === 2 || v.requiredItemClass === 4) {
                const item = v.item || 'n';
                const itemSubclassMask = v.itemSubclassMask || 'n';
                const invTypeMask = v.invTypeMask || 'n';
                codes.push(
                    `D(${v.enchant},${v.spell},${item},${v.requiredItemClass},${itemSubclassMask},${invTypeMask})`
                );
            }
        }

        const code = `---@diagnostic disable: undefined-global
select(2,...).ItemEnchantMake()
local n=nil
${codes.join('\n')}`;

        Deno.writeTextFileSync(file, code);
    }
}

new App(ProjectId.Wrath).run('Data/Wrath/ItemEnchant.lua');
new App(ProjectId.Vanilla).run('Data/Vanilla/ItemEnchant.lua');
