/**
 * @File   : ItemEnchantGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 9/4/2024, 2:23:31 PM
 */

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
    async run() {
        const resp = await fetch('https://nether.wowhead.com/wotlk/data/gear-planner?dv=100');
        const text = await resp.text();

        const m = text.match(/"wow\.gearPlanner\.wrath.enchant",(.+)\)/);
        if (!m) {
            throw Error('not found');
        }
        const d = JSON.parse(m[1]) as ItemEnchantMap | undefined;

        if (!d) {
            throw Error('not found');
        }

        const codes = [];

        for (const [, v] of Object.entries(d)) {
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

        const code = `select(2,...).ItemEnchantMake()
local n=nil
${codes.join('\n')}`;

        Deno.writeTextFileSync('Data/Wrath/ItemEnchant.lua', code);
    }
}

new App().run();
