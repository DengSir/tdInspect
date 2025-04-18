/**
 * @File   : util.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:55:36
 */
import { format } from "@miyauci/format";
import { Semaphore } from "@core/asyncutil/semaphore";
import { Html5Entities } from 'https://deno.land/x/html_entities@v1.0/mod.js';

export enum ProjectId {
    Vanilla,
    BCC,
    Wrath,
    Cata,
}

interface ProjectData {
    version: string;
    product: string;
    version_pattern?: RegExp;
}

const WOW_TOOLS = 'https://wow.tools/dbc/api/export/';
const WOW_TOOLS2 = 'https://wago.tools/db2/{name}/csv';
const PROJECTS = new Map([
    [ProjectId.Vanilla, { product: 'wow_classic_era' }],
    [ProjectId.Wrath, { product: 'wow_classic', version_pattern: /^3\..+/ }],
    [ProjectId.Cata, { product: 'wow_classic', version_pattern: /^4\..+/ }],
]);

export function mapLimit<T, U>(array: T[], limit: number, fn: (value: T, index: number, array: T[]) => U) {
    const sem = new Semaphore(limit);
    return array.map((...args) => sem.lock(() => fn(...args)));
}

export class WowToolsClient {
    private pro: ProjectData;

    constructor(projectId: ProjectId) {
        const data = PROJECTS.get(projectId);
        if (!data) {
            throw Error('');
        }

        this.pro = data as ProjectData;
    }

    private async fetchVersions() {
        const resp = await fetch('https://wago.tools/db2');
        const body = await resp.text();
        const match = [...body.matchAll(/data-page="([^"]+)"/g)];
        if (!match || match.length < 1) {
            throw Error('');
        }

        const data = JSON.parse(Html5Entities.decode(match[0][1]));
        const versions = data?.props?.versions;
        return new Set(versions)
    }

    private async fetchVersion() {
        const exists = await this.fetchVersions();
        const resp = await fetch('https://wago.tools/api/builds');
        const data = await resp.json();

        const versions = data[this.pro.product];
        if (!versions) {
            throw Error();
        }

        if (this.pro.version_pattern) {
            for (const v of versions) {
                if (exists.has(v.version) && this.pro.version_pattern.test(v.version)) {
                    return v.version as string;
                }
            }
        } else {
            for (const v of versions) {
                if (exists.has(v.version)) {
                    return v.version as string;
                }
            }
        }
        return '';
    }

    decodeFields(data: string) {
        const fields = data.split(',').map((x, i) => ({ name: x, index: i }));
        const info: any = {};

        for (const field of fields) {
            const m = /^(.+)_(\d+)$/g.exec(field.name);

            if (!m) {
                info[field.name] = field.index;
            } else {
                const arrayName = m[1];
                const arrayIndex = Number.parseInt(m[2]);

                info[arrayName] = info[arrayName] || [];
                info[arrayName][arrayIndex] = field.index;
            }
        }
        return info;
    }

    decodeRow(fields: any[], data: string) {
        const row = data.split(',').map((x) => this.parseString(x));
        const obj: any = {};

        for (const [name, index] of Object.entries(fields)) {
            if (Array.isArray(index)) {
                obj[name] = index.map((i) => row[i]);
            } else {
                obj[name] = row[index];
            }
        }
        return obj;
    }

    decodeCSV(data: string) {
        const rows = data.split(/[\r\n]+/).filter((x) => x);
        const fields = this.decodeFields(rows.splice(0, 1)[0]);

        return rows.map((x) => this.decodeRow(fields, x));
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
            console.log('version', this.pro.version);
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
