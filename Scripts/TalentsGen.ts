/**
 * @File   : TalentsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 14:22:02
 */

import * as path from '@std/path';
import { ProjectId, WowToolsClient } from './util.ts';

interface Config {
    hasId: boolean;
    hasIcon: boolean;
}

const PROJECTS: { [key: number]: Config } = {
    [ProjectId.Vanilla]: { hasId: false, hasIcon: true },
    [ProjectId.BCC]: { hasId: true, hasIcon: false },
    [ProjectId.Wrath]: { hasId: true, hasIcon: true },
    [ProjectId.Cata]: { hasId: true, hasIcon: true },
};

const LOCALES: [n: number, l: string, resolve?: string][] = [
    [0, 'enUS'],
    [1, 'koKR'],
    [2, 'frFR'],
    [3, 'deDE'],
    [4, 'zhCN'],
    [5, 'zhTW'],
    [6, 'esES'],
    [7, 'ruRU'],
    [8, 'ptBR'],
    [9, 'itIT', 'enUS'],
];

class App {
    private prj: Config;
    private cli: WowToolsClient;

    constructor(projectId: number) {
        this.prj = PROJECTS[projectId];
        this.cli = new WowToolsClient(projectId);
    }

    async getClasses() {
        const csv = await this.cli.fetchTable('ChrClasses');
        return csv.map((x) => ({
            id: Number.parseInt(x.ID),
            fileName: x.Filename,
            classMask: 1 << (Number.parseInt(x.ID) - 1),
        }));
    }

    async getTalentTabNames(locale: string) {
        const csv = await this.cli.fetchTable('talenttab', locale);
        return new Map(csv.map((x) => [Number.parseInt(x.ID), x.Name_lang]));
    }

    async getTalentTabs() {
        const csv = await this.cli.fetchTable('talenttab');
        const names = new Map(
            await Promise.all(
                LOCALES.map(
                    async ([, l, r]) => [l, await this.getTalentTabNames(r ? r : l)] as [string, Map<number, string>]
                )
            )
        );

        return csv
            .filter((x) => Number.parseInt(x.OrderIndex) >= 0)
            .map((x) => ({
                id: Number.parseInt(x.ID),
                bg: x.BackgroundFile,
                order: Number.parseInt(x.OrderIndex),
                classMask: Number.parseInt(x.ClassMask),
                icon: Number.parseInt(x.SpellIconID),
                names: LOCALES.map(([, l]) => l).map((l) => names.get(l)?.get(Number.parseInt(x.ID))),
            }));
    }

    async getTalents() {
        const csv = await this.cli.fetchTable('talent');

        return csv.map((x, i) => ({
            index: i,
            id: Number.parseInt(x.ID),
            tier: Number.parseInt(x.TierID),
            col: Number.parseInt(x.ColumnIndex),
            tabId: Number.parseInt(x.TabID),
            spells: (x.SpellRank as string[]).map((x) => Number.parseInt(x)).filter((x) => x),
            reqs: (x.PrereqTalent as string[]).map((x) => Number.parseInt(x)).filter((x) => x),
        }));
    }

    async run(output: string) {
        const classes = await this.getClasses();
        const tabs = await this.getTalentTabs();
        const talents = await this.getTalents();

        const talentsMap = new Map(talents.map((x) => [x.id, x]));

        for (const cls of classes) {
            let n = 0;

            const classTabs = tabs.filter((tab) => tab.classMask === cls.classMask).sort((a, b) => a.order - b.order);

            for (const tab of classTabs) {
                if (tab.classMask === cls.classMask) {
                    const tabTalents = talents.filter((talent) => talent.tabId === tab.id);

                    tabTalents.forEach((x, i) => (x.index = i + 1 + n));
                    n = tabTalents.length;
                }
            }
        }

        const classTabs = classes.map((cls) => ({
            ...cls,
            tabs: tabs
                .filter((tab) => tab.classMask === cls.classMask)
                .sort((a, b) => a.order - b.order)
                .map((tab) => ({
                    talents: talents
                        .filter((talent) => talent.tabId === tab.id)
                        .sort((a, b) => {
                            if (a.tabId !== b.tabId) {
                                return a.tabId - b.tabId;
                            }
                            if (a.tier !== b.tier) {
                                return a.tier - b.tier;
                            }
                            return a.col - b.col;
                        }),
                    ...tab,
                })),
        }));

        console.log(`Generate ${output}`);

        Deno.mkdirSync(path.dirname(output), { recursive: true });

        const file = Deno.openSync(output, { write: true, create: true, truncate: true });
        const encoder = new TextEncoder();
        const write = (x: string) => file.writeSync(encoder.encode(x));

        write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY TalentsGen.ts
select(2,...).TalentMake()`
        );

        write(`D'${LOCALES.map(([, l]) => l).join('/')}'`);
        write('\n');

        for (const cls of classTabs) {
            console.log(`For ${cls.fileName}`);

            write(`C'${cls.fileName}'\n`);

            for (const tab of cls.tabs) {
                {
                    write(`T(${tab.id},${tab.talents.length},'${tab.bg}'`);
                    if (this.prj.hasIcon) {
                        write(`,${tab.icon}`);
                    }
                    write(')');
                }

                write(`N'${tab.names.join('/')}'`);
                write('\n');

                for (const talent of tab.talents) {
                    {
                        write(`I(${talent.index},${talent.tier + 1},${talent.col + 1},${talent.spells.length}`);
                        if (this.prj.hasId) {
                            write(`,${talent.id}`);
                        }
                        write(')');
                    }

                    write(`R{${talent.spells.join(',')}}`);

                    if (talent.reqs && talent.reqs.length > 0) {
                        for (const req of talent.reqs) {
                            const reqTalent = talentsMap.get(req);
                            if (reqTalent) {
                                const reqIndex = tab.talents.findIndex((x) => x.id == req);
                                write(`P(${reqTalent.tier + 1},${reqTalent.col + 1},${reqIndex + 1})`);
                            }
                        }
                    }
                    write('\n');
                }
            }
        }

        file.close();
    }
}

async function main() {
    await new App(ProjectId.Wrath).run('Data/Wrath/Talents.lua');
    await new App(ProjectId.Cata).run('Data/Cata/Talents.lua');
    await new App(ProjectId.Vanilla).run('Data/Vanilla/Talents.lua');
}

main();
