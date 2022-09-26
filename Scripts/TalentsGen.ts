/**
 * @File   : TalentsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 14:22:02
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
    private project: ProjectData;

    constructor(projectId: number) {
        this.project = PROJECTS[projectId];
    }

    fetchData(name: string, locale = 'enUS') {
        return fetchData(WOW_TOOLS, { name, locale, build: this.project.version });
    }

    async getClasses() {
        const csv = await this.fetchData('chrclasses');
        return csv.map((x) => ({
            id: Number.parseInt(x[5]),
            fileName: x[1],
            classMask: 1 << (Number.parseInt(x[5]) - 1),
        }));
    }

    async getTalentTabNames(locale: string) {
        const csv = await this.fetchData('talenttab', locale);
        return new Map(csv.map(([id, name]) => [Number.parseInt(id), name]));
    }

    async getTalentTabs() {
        const csv = await this.fetchData('talenttab');
        const names = new Map(
            await Promise.all(
                LOCALES.map(
                    async ([, l, r]) => [l, await this.getTalentTabNames(r ? r : l)] as [string, Map<number, string>]
                )
            )
        );

        return csv.map((x) => ({
            id: Number.parseInt(x[0]),
            bg: x[2],
            order: Number.parseInt(x[3]),
            classMask: Number.parseInt(x[5]),
            icon: Number.parseInt(x[7]),
            names: LOCALES.map(([, l]) => l).map((l) => names.get(l)?.get(Number.parseInt(x[0]))),
        }));
    }

    async getTalents() {
        const csv = await this.fetchData('talent');

        return csv
            .map((x) => ({
                id: Number.parseInt(x[0]),
                tier: Number.parseInt(x[2]),
                col: Number.parseInt(x[4]),
                tabId: Number.parseInt(x[5]),
                spells: x
                    .slice(13, 21)
                    .map((x) => Number.parseInt(x))
                    .filter((x) => x),
                reqs: x
                    .slice(22, 24)
                    .map((x) => Number.parseInt(x))
                    .filter((x) => x),
            }))
            .sort((a, b) => {
                if (a.tabId !== b.tabId) {
                    return a.tabId - b.tabId;
                }
                if (a.tier !== b.tier) {
                    return a.tier - b.tier;
                }
                return a.col - b.col;
            });
    }

    async run(output: string) {
        const classes = await this.getClasses();
        const tabs = await this.getTalentTabs();
        const talents = await this.getTalents();

        const talentsMap = new Map(talents.map((x) => [x.id, x]));

        const classTabs = classes.map((cls) => ({
            ...cls,
            tabs: tabs
                .filter((tab) => tab.classMask === cls.classMask)
                .sort((a, b) => a.order - b.order)
                .map((tab) => ({
                    talents: talents.filter((talent) => talent.tabId === tab.id),
                    ...tab,
                })),
        }));

        console.log(`Generate ${output}`);

        const file = Deno.openSync(output, { write: true, create: true, truncate: true });
        const encoder = new TextEncoder();
        const write = (x: string) => file.writeSync(encoder.encode(x));

        write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY TalentsGen.ts
select(2,...).TalentMake()`
        );

        write(`D'${LOCALES.map(([, l]) => l).join('/')}'`);

        for (const cls of classTabs) {
            console.log(`For ${cls.fileName}`);

            write(`C'${cls.fileName}'`);

            for (const tab of cls.tabs) {
                {
                    write(`T(${tab.id},${tab.talents.length},'${tab.bg}'`);
                    if (this.project.hasIcon) {
                        write(`,${tab.icon}`);
                    }
                    write(')');
                }

                write(`N'${tab.names.join('/')}'`);

                for (const talent of tab.talents) {
                    {
                        write(`I(${talent.tier + 1},${talent.col + 1},${talent.spells.length}`);
                        if (this.project.hasId) {
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
                }
            }
        }

        file.close();
    }
}

async function main() {
    await new App(11).run('Data/Talents.WLK.lua');
    await new App(5).run('Data/Talents.BCC.lua');
    await new App(2).run('Data/Talents.lua');
}

main();
