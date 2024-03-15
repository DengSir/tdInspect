/**
 * @File   : util.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:55:36
 */
import { format } from 'https://deno.land/x/format/mod.ts';

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
const WOW_TOOLS2 = 'https://wago.tools/db2/{name}/csv';
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
        return rows.map((x) => x.split(',').map((i) => this.parseString(i)));
    }

    private parseString(x: string) {
        try {
            const v = JSON.parse(x);
            if (typeof v === 'string') {
                return v;
            }
        } catch {
            //
        }
        return x;
    }

    async fetchTable(name: string, locale = 'enUS', source = 2) {
        const url = (() => {
            let url;
            if (source == 2) {
                url = new URL(format(WOW_TOOLS2, { name }));
                url.searchParams.append('build', this.pro.version);
                url.searchParams.append('locale', locale);
            } else if (source == 1) {
                url = new URL(WOW_TOOLS);
                url.searchParams.append('name', name);
                url.searchParams.append('build', this.pro.version);
                url.searchParams.append('locale', locale);
            } else {
                throw Error();
            }
            return url;
        })();

        const resp = await fetch(url);
        const body = await resp.text();
        return this.decodeCSV(body);
    }
}
