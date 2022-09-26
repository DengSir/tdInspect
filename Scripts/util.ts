/**
 * @File   : util.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:55:36
 */

export enum ProjectId {
    Classic = 2,
    BCC = 5,
    WLK = 11,
}

interface ProjectData {
    version: string;
    dataEnv: number;
}

const WOW_TOOLS = 'https://wow.tools/dbc/api/export/';

const PROJECTS = new Map([
    [ProjectId.Classic, { version: '1.14.3.44834', dataEnv: 4 }],
    [ProjectId.BCC, { version: '2.5.4.44833', dataEnv: 5 }],
    [ProjectId.WLK, { version: '3.4.0.45770', dataEnv: 8 }],
]);

export class WowToolsClient {
    private pro: ProjectData;

    constructor(projectId: ProjectId) {
        const data = PROJECTS.get(projectId);
        if (!data) {
            throw Error('');
        }

        this.pro = data;
    }

    decodeCSV(data: string) {
        const rows = data.split(/[\r\n]+/).filter((x) => x);
        // const headers = rows[0].split(',');
        rows.splice(0, 1);
        return rows.map((x) => x.split(','));
    }

    async fetchTable(name: string, locale = 'enUS') {
        const url = new URL(WOW_TOOLS);
        url.searchParams.append('name', name);
        url.searchParams.append('build', this.pro.version);
        url.searchParams.append('locale', locale);

        const resp = await fetch(url);
        const body = await resp.text();
        return this.decodeCSV(body);
    }
}
