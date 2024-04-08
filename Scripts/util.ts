/**
 * @File   : util.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:55:36
 */
import { format } from 'https://deno.land/x/format/mod.ts';
import { Html5Entities } from 'https://deno.land/x/html_entities@v1.0/mod.js';

export enum ProjectId {
    Classic = 2,
    BCC = 5,
    WLK = 11,
}

interface ProjectData {
    version?: string;
    product: string;
}

const WOW_TOOLS = 'https://wow.tools/dbc/api/export/';
const WOW_TOOLS2 = 'https://wago.tools/db2/{name}/csv';
const PROJECTS = new Map([
    [ProjectId.Classic, { product: 'wow_classic_era' }],
    [ProjectId.WLK, { product: 'wow_classic' }],
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

    private async fetchVersion() {
        const resp = await fetch('https://wago.tools');
        const body = await resp.text();

        const match = [...body.matchAll(/data-page="([^"]+)"/g)];
        if (!match || match.length < 1) {
            throw Error();
        }

        const data = JSON.parse(Html5Entities.decode(match[0][1]));

        const versions = data?.props?.versions as { product: string; version: string }[];
        const version = versions?.filter(({ product }) => product === this.pro.product)[0].version;
        if (!version) {
            throw Error();
        }
        return version;
    }

    decodeCSV(data: string) {
        const rows = data.split(/[\r\n]+/).filter((x) => x);
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
        if (!this.pro.version) {
            this.pro.version = await this.fetchVersion();
        }
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
