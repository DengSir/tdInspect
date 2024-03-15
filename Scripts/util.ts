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

const PROJECTS = new Map([
    [ProjectId.Classic, { version: '1.15.1.53623', dataEnv: 4 }],
    [ProjectId.BCC, { version: '2.5.4.44833', dataEnv: 5 }],
    [ProjectId.WLK, { version: '3.4.3.52237', dataEnv: 8 }],
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
        return rows.map((x) => x.split(',').map((x) => x.replace(/\"/g, '')));
    }

    async fetchTable(name: string, locale = 'enUS') {
        const url = new URL(`https://wago.tools/db2/${name}/csv?build=${this.pro.version}&locale=${locale}`);
        // url.searchParams.append('name', name);
        // url.searchParams.append('build', this.pro.version);
        // url.searchParams.append('locale', locale);

        const resp = await fetch(url);
        const body = await resp.text();
        return this.decodeCSV(body);
    }
}
