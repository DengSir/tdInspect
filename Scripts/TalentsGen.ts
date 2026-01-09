/**
 * @File   : TalentsGen.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 14:22:02
 */

import { FileIo, ProjectId, WowToolsClient } from './util.ts';

enum TalentType {
    Tree, // 天赋树
    Class,// 职业
    Spec, // 专精
}

interface Config {
    hasId: boolean;
    hasIcon: boolean;
    talentType: TalentType;
}

const PROJECTS: { [key: number]: Config } = {
    [ProjectId.Vanilla]: { hasId: false, hasIcon: true, talentType: TalentType.Tree },
    [ProjectId.Wrath]: { hasId: true, hasIcon: true, talentType: TalentType.Tree },
    [ProjectId.Mists]: { hasId: true, hasIcon: true, talentType: TalentType.Class },
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

    constructor(private projectId: number) {
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
        const csv = await this.cli.fetchTable('talent') as any[];

        // hotfixes for wrath
        if (this.projectId == ProjectId.Wrath && this.cli.pro.version === '3.80.0.64859') {
            {
                const item = csv.find((x) => x.ID === '901')
                item.ColumnIndex = '3';
            }
            {
                const item = csv.find((x) => x.ID === '2054')
                item.ColumnIndex = '3';
            }

            {
                const item = csv.find((x) => x.ID === '2078')
                item.SpellRank = ['51701']
            }
            {
                const item = csv.find((x) => x.ID === '2140')
                item.TierID = '10'
                item.ColumnIndex = '1'
                item.SpellRank = ['1284198']
            }
            {
                const item = csv.find((x) => x.ID === '2139')
                item.TierID = '9'
                item.ColumnIndex = '2'
                item.PrereqTalent = ['2227']
                item.PrereqRank = ['4'];
            }
            {
                const item = csv.find((x) => x.ID === '2136')
                item.SpellRank = ['1284199']
                item.PrereqTalent = ['1800'];
                item.PrereqRank = ['2'];
            }

            csv.push({
                'ID': '23706',
                'TierID': '6',
                'ColumnIndex': '2',
                'SpellRank': ['1283508', '1283509', '1283510'],
                'TabID': '263',
                'ClassID': '7',
                'SpellID': '23706',
                'PrereqTalent': ['1690'],
            })
            csv.push({
                'ID': '23707',
                'TierID': '6',
                'ColumnIndex': '3',
                'SpellRank': ['1284398'],
                'TabID': '183',
                'ClassID': '4',
                'PrereqTalent': [],
            });
            csv.push({
                'ID': '23708',
                'TierID': '7',
                'ColumnIndex': '3',
                'SpellRank': ['1284400'],
                'PrereqTalent': ['23707'],
                'TabID': '183',
                'ClassID': '4',
            });
        }

        return csv.map((x, i) => ({
            index: i,
            id: Number.parseInt(x.ID),
            tier: Number.parseInt(x.TierID),
            col: Number.parseInt(x.ColumnIndex),
            tabId: Number.parseInt(x.TabID),
            classId: Number.parseInt(x.ClassID),
            spellId: Number.parseInt(x.SpellID),
            spells: (x.SpellRank as string[]).map((x) => Number.parseInt(x)).filter((x) => x),
            reqs: (x.PrereqTalent as string[]).map((x) => Number.parseInt(x)).filter((x) => x),
        }));
    }

    async runByTree(output: string) {
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
                    n += tabTalents.length;
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

        const io = new FileIo(output);
        io.write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY TalentsGen.ts
select(2,...).TalentMake()`
        );

        io.write(`D'${LOCALES.map(([, l]) => l).join('/')}'`);
        io.write('\n');

        for (const cls of classTabs) {
            console.log(`For ${cls.fileName}`);

            io.write(`C'${cls.fileName}'\n`);

            for (const tab of cls.tabs) {
                {
                    io.write(`T(${tab.id},${tab.talents.length},'${tab.bg}'`);
                    if (this.prj.hasIcon) {
                        io.write(`,${tab.icon}`);
                    }
                    io.write(')');
                }

                io.write(`N'${tab.names.join('/')}'`);
                io.write('\n');

                for (const talent of tab.talents) {
                    {
                        io.write(`I(${talent.index},${talent.tier + 1},${talent.col + 1},${talent.spells.length}`);
                        if (this.prj.hasId) {
                            io.write(`,${talent.id}`);
                        }
                        io.write(')');
                    }

                    io.write(`R{${talent.spells.join(',')}}`);

                    if (talent.reqs && talent.reqs.length > 0) {
                        for (const req of talent.reqs) {
                            const reqTalent = talentsMap.get(req);
                            if (reqTalent) {
                                const reqIndex = tab.talents.findIndex((x) => x.id == req);
                                io.write(`P(${reqTalent.tier + 1},${reqTalent.col + 1},${reqIndex + 1})`);
                            }
                        }
                    }
                    io.write('\n');
                }
            }
        }

        io.close();
    }

    async getSpecTabs() {
        const csv = await this.cli.fetchTable('ChrSpecialization');

        return csv.filter((x) => Number.parseInt(x.MasterySpellID[0]) !== 0).map((x) => ({
            id: Number.parseInt(x.ID),
            classId: Number.parseInt(x.ClassID),
            order: Number.parseInt(x.OrderIndex),
            icon: Number.parseInt(x.SpellIconFileID),
        }));
    }

    async runByClass(output: string) {
        const classes = await this.getClasses();
        const tabs = await this.getSpecTabs();
        const talents = await this.getTalents();

        console.log(`Generate ${output}`);

        const io = new FileIo(output);
        io.write(
            `---@diagnostic disable: undefined-global
-- GENERATE BY TalentsGen.ts
select(2,...).TalentMake()`
        );

        io.write(`D'${LOCALES.map(([, l]) => l).join('/')}'`);
        io.write('\n');

        for (const cls of classes) {
            console.log(`For ${cls.fileName} ${cls.id}`);

            const specs = tabs.filter((tab) => tab.classId === cls.id).sort((a, b) => a.order - b.order);

            io.write(`C'${cls.fileName}'\n`);

            for (const spec of specs) {
                io.write(`S(${spec.id},${spec.icon})\n`);
            }

            const rows = 6;
            for (let tier = 0; tier < rows; tier++) {
                const lineTalents = talents.filter((x) => x.classId === cls.id && x.tier === tier).sort((a, b) => a.col - b.col).map(x => x.spellId)

                io.write(`T(${lineTalents.join(',')})\n`);
            }
        }

        io.close();
    }

    async run(output: string) {
        if (this.prj.talentType === TalentType.Tree) {
            await this.runByTree(output);
        } else if (this.prj.talentType === TalentType.Class) {
            await this.runByClass(output);
        }
    }
}

async function main() {
    await new App(ProjectId.Vanilla).run('Data/Vanilla/Talents.lua');
    await new App(ProjectId.Wrath).run('Data/Wrath/Talents.lua');
    await new App(ProjectId.Mists).run('Data/Mists/Talents.lua');
}

main();
