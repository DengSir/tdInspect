/**
 * @File   : ItemEnchantGen2.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 11/19/2025, 1:52:26 PM
 */

import { ProjectId, WowToolsClient } from "./util.ts";

class App {
    private cli: WowToolsClient;

    constructor(private projectId: ProjectId) {
        this.cli = new WowToolsClient(projectId);
    }

    isAsciiOnly(str: string) {
        return /^[\x00-\x7F]*$/.test(str);
    }

    isTestName(name: string) {
        return this.isAsciiOnly(name) && (name.startsWith('Test') || name.startsWith('QA') || name.startsWith('(DNT)') || name.includes('OLD') || name.includes('TEST') || name.includes('[DNT]'));
    }

    async fetchSpells() {
        const spells = (await this.cli.fetchTable('SpellName', 'zhCN'))
            .filter(x => x['Name_lang'].length > 0 && !this.isTestName(x['Name_lang']));
        return new Set(spells.map(x => Number.parseInt(x.ID) || 0));
    }

    async fetchSpellEffects() {
        const spellEffects = await this.cli.fetchTable('SpellEffect');

        return spellEffects.map(x => ({
            effect: Number.parseInt(x.Effect) || 0,
            effectItemType: Number.parseInt(x.EffectItemType) || 0,
            enchantId: x.EffectMiscValue.length > 0 ? Number.parseInt(x.EffectMiscValue[0]) : 0,
            spellId: Number.parseInt(x.SpellID) || 0,
        })).filter(x => x.effect === 53 && x.enchantId > 0);
    }

    async fetchEnchants() {
        const enchants = await this.cli.fetchTable('SpellItemEnchantment');
        return enchants.map(x => Number.parseInt(x.ID) || 0).filter(x => x > 0).sort((a, b) => a - b);
    }

    async fetchItems() {
        const items = (await this.cli.fetchTable('ItemSparse', 'zhCN')).filter(x => Number.parseInt(x.Flags[0]) !== 10).filter(x => !this.isAsciiOnly(x['Display_lang']));
        return new Set(items.map(x => Number.parseInt(x.ID) || 0));
    }

    async fetchItemEffects() {
        const itemEffects = await this.cli.fetchTable('ItemEffect');
        return itemEffects.map(x => ({
            spellId: Number.parseInt(x.SpellID) || 0,
            triggerType: Number.parseInt(x.TriggerType) || 0,
            itemId: Number.parseInt(x.ParentItemID) || 0,
        })).filter(x => x.triggerType === 0 && x.itemId > 0);
    }

    async fetchSpellEquippedItems() {
        const spellEquippedItems = await this.cli.fetchTable('SpellEquippedItems');
        return spellEquippedItems.map(x => ({
            spellId: Number.parseInt(x.SpellID) || 0,
            itemClass: Number.parseInt(x.EquippedItemClass) || 0,
            itemSubClass: Number.parseInt(x.EquippedItemSubclass) || 0,
            invType: Number.parseInt(x.EquippedItemInvTypes) || 0,
        }));
    }

    async run(file: string) {
        const enchants = await this.fetchEnchants();
        const spells = await this.fetchSpells();
        const spellEffects = (await this.fetchSpellEffects()).filter(x => spells.has(x.spellId));
        const itemEffects = await this.fetchItemEffects();
        const spellEquippedItems = await this.fetchSpellEquippedItems();
        const items = await this.fetchItems();

        const spellItems = new Map(itemEffects.map(x => [x.spellId, x.itemId]));
        const spellEquippedItemsMap = new Map(spellEquippedItems.map(x => [x.spellId, x]));

        const codes = [];

        for (const id of enchants) {
            const spells = spellEffects.filter(x => x.enchantId === id).sort((a, b) => a.spellId - b.spellId);
            for (const spell of spells) {
                const itemId = spellItems.get(spell.spellId);
                const equippedItem = spellEquippedItemsMap.get(spell.spellId);

                if (equippedItem && (equippedItem.itemClass === 2 || equippedItem.itemClass === 4)) {
                    const item = itemId && items.has(itemId) ? itemId : 0;
                    const itemSubclassMask = equippedItem.itemSubClass || 0;
                    const invTypeMask = equippedItem.invType || 0;
                    codes.push(
                        `D(${id},${spell.spellId},${item},${equippedItem.itemClass},${itemSubclassMask},${invTypeMask})`
                    );
                }
            }
        }

        const code = `---@diagnostic disable: undefined-global
select(2,...).ItemEnchantMake()
local n=nil
${codes.join('\n')}`;

        Deno.writeTextFileSync(file, code);
    }
}

async function main() {
    await new App(ProjectId.Vanilla).run('Data/Vanilla/ItemEnchant.lua');
    await new App(ProjectId.BCC).run('Data/TBC/ItemEnchant.lua');
    await new App(ProjectId.Wrath).run('Data/Wrath/ItemEnchant.lua');
    await new App(ProjectId.Mists).run('Data/Mists/ItemEnchant.lua');
}
main();
