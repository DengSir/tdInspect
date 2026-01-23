/**
 * @File   : util.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:55:36
 */


import { parse } from "@std/csv/parse";
import { format } from "@miyauci/format";
import { Semaphore } from "@core/asyncutil/semaphore";
import { Html5Entities } from 'https://deno.land/x/html_entities@v1.0/mod.js';
import { crypto } from "@std/crypto";
import { encodeHex } from "@std/encoding/hex";
import * as path from '@std/path';
import * as fs from '@std/fs';


export enum ProjectId {
    Vanilla,
    BCC,
    Wrath,
    Cata,
    Mists,
}

interface ProjectData {
    version: string;
    product: string;
    // version_pattern?: RegExp;
}

const WOW_TOOLS = 'https://wow.tools/dbc/api/export/';
const WOW_TOOLS2 = 'https://wago.tools/db2/{name}/csv';
const PROJECTS = new Map([
    [ProjectId.Vanilla, { product: 'wow_classic_era' }],
    [ProjectId.Wrath, { product: 'wow_classic_titan' }],
    [ProjectId.Mists, { product: 'wow_classic' }],
]);

export function mapLimit<T, U>(array: T[], limit: number, fn: (value: T, index: number, array: T[]) => U) {
    const sem = new Semaphore(limit);
    return array.map((...args) => sem.lock(() => fn(...args)));
}

type Fields = { [key: string]: number | number[] };

export class WowToolsClient {
    pro: ProjectData;

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
        // const exists = await this.fetchVersions();
        const resp = await fetch('https://wago.tools/api/builds');
        const data = await resp.json();

        const versions = data[this.pro.product];
        if (!versions) {
            throw Error();
        }

        // if (this.pro.version_pattern) {
        //     for (const v of versions) {
        //         if (exists.has(v.version) && this.pro.version_pattern.test(v.version)) {
        //             return v.version as string;
        //         }
        //     }
        // } else {
        for (const v of versions) {
            // if (exists.has(v.version)) {
            return v.version as string;
            // }
        }
        // }
        return '';
    }

    decodeFields(row: string[]) {
        const fields = row.map((x, i) => ({ name: x, index: i }));
        const info: Fields = {};

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

    decodeRow(fields: Fields, row: string[]) {
        const obj: { [key: string]: string | string[] } = {};

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
        const rows = parse(data);
        const fields = this.decodeFields(rows.splice(0, 1)[0]);
        return rows.map((x) => this.decodeRow(fields, x));
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

        // const urlhash = name + '_' + encodeHex(await crypto.subtle.digest('MD5', new TextEncoder().encode(url.toString())));
        // const p = path.resolve('.cache', urlhash);
        // if (await fs.exists(p)) {
        //     const body = await Deno.readTextFile(p);
        //     return this.decodeCSV(body);
        // }

        const resp = await fetch(url);
        let body = await resp.text();

        if (name === 'talent' && this.pro.version === '3.80.0.65301') {
            console.log('fetched talent for wrath hotfix');

            const lines = body.split('\n');

            const patch = (id: number, newLine: string) => {
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];

                    if (line.startsWith(`${id},`)) {
                        lines[i] = newLine;
                        return;
                    }
                }

                lines.push(newLine);
            }

            const remove = (id: number) => {
                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];

                    if (line.startsWith(`${id},`)) {
                        lines.splice(i, 1);
                        return;
                    }
                }
            }

            patch(64, '64, , 4, 0, 2, 61, 8, 0, 0, 0, 0, 0, 0, 11190, 12489, 12490, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(1740, '1740, , 7, 0, 1, 61, 8, 0, 0, 0, 0, 0, 0, 31682, 31683, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(1854, '1854, , 8, 0, 0, 61, 8, 0, 0, 0, 0, 0, 0, 44546, 44548, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(1855, '1855, , 8, 0, 2, 61, 8, 0, 0, 0, 0, 0, 0, 44561, 0, 0, 0, 0, 0, 0, 0, 0, 1741, 0, 0, 0, 0, 0 ')
            patch(23709, '23709, , 8, 1, 3, 61, 8, 0, 0, 0, 0, 0, 0, 1284421, 0, 0, 0, 0, 0, 0, 0, 0, 23710, 0, 0, 4, 0, 0 ')
            patch(23710, '23710, , 6, 0, 3, 61, 8, 0, 0, 0, 0, 0, 0, 1284510, 1284521, 1284522, 1285506, 1285507, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(23711, '23711, , 0, 0, 3, 61, 8, 0, 0, 0, 0, 0, 0, 1284534, 1284535, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(23712, '23712, , 7, 0, 0, 61, 8, 0, 0, 0, 0, 0, 0, 1284602, 0, 0, 0, 0, 0, 0, 0, 0, 1740, 0, 0, 1, 0, 0 ')
            patch(2136, '2136, , 7, 1, 0, 361, 3, 0, 0, 0, 0, 0, 0, 1284199, 0, 0, 0, 0, 0, 0, 0, 0, 1800, 0, 0, 2, 0, 0 ')
            patch(2139, '2139, , 9, 1, 2, 361, 3, 0, 0, 0, 0, 0, 0, 53270, 0, 0, 0, 0, 0, 0, 0, 0, 2227, 0, 0, 4, 0, 0 ')
            patch(2140, '2140, , 10, 1, 1, 361, 3, 0, 0, 0, 0, 0, 0, 1284198, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(2227, '2227, , 9, 0, 1, 361, 3, 0, 0, 0, 0, 0, 0, 56314, 56315, 56316, 56317, 56318, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(2078, '2078, , 8, 0, 0, 183, 4, 0, 0, 0, 0, 0, 0, 51701, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(23707, '23707, , 6, 1, 3, 183, 4, 0, 0, 0, 0, 0, 0, 1284398, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ')
            patch(23708, '23708, , 7, 1, 3, 183, 4, 0, 0, 0, 0, 0, 0, 1284400, 0, 0, 0, 0, 0, 0, 0, 0, 23707, 0, 0, 0, 0, 0 ')

            remove(23713)

            body = lines.join('\n');
        }

        // await Deno.mkdir(path.dirname(p), { recursive: true });
        // await Deno.writeTextFile(p, body);
        return this.decodeCSV(body);
    }
}

export class FileIo {
    private sb: string[] = [];

    constructor(public fileName: string) { }

    write(content: string) {
        this.sb.push(content)
    }

    close() {
        Deno.mkdirSync(path.dirname(this.fileName), { recursive: true });

        const file = Deno.openSync(this.fileName, { create: true, write: true, truncate: true });
        const encoder = new TextEncoder();
        file.writeSync(encoder.encode(this.sb.join('')));
        file.close();
    }
}
