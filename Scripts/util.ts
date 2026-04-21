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
    [ProjectId.BCC, { product: 'wow_anniversary' }],
    [ProjectId.Wrath, { product: 'wow_classic_titan' }],
    [ProjectId.Mists, { product: 'wow_classic' }],
]);

export function mapLimit<T, U>(array: T[], limit: number, fn: (value: T, index: number, array: T[]) => U) {
    const sem = new Semaphore(limit);
    return array.map((...args) => sem.lock(() => fn(...args)));
}

interface FieldInfo {
    name: string;
    index: number[];
}

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

    decodeFields(row: string[]): FieldInfo[] {
        const order: string[] = [];
        const idxMap: { [key: string]: (number | undefined)[] } = {};

        for (let i = 0; i < row.length; i++) {
            const hdr = row[i];
            const m = /^(.+)_(\d+)$/g.exec(hdr);
            const key = m ? m[1] : hdr;

            if (!idxMap[key]) {
                idxMap[key] = [];
                order.push(key);
            }

            if (m) {
                idxMap[key][Number(m[2])] = i;
            } else {
                idxMap[key] = [i];
            }
        }

        const result: FieldInfo[] = [];
        for (const key of order) {
            const arr = idxMap[key];
            if (arr.length === 1) {
                result.push({ name: key, index: [arr[0]!] });
            } else {
                result.push({ name: key, index: arr.filter((v) => v !== undefined) as number[] });
            }
        }

        return result;
    }

    decodeRow(fields: FieldInfo[], row: string[]) {
        const obj: { [key: string]: string | string[] } = {};

        for (const f of fields) {
            if (f.index.length > 1) {
                obj[f.name] = f.index.map((i) => row[i]);
            } else {
                obj[f.name] = row[f.index[0]];
            }
        }
        return obj;
    }

    decodeCSV(data: string): [{ [key: string]: string | string[] }[], FieldInfo[]] {
        const rows = parse(data);
        const fields = this.decodeFields(rows.splice(0, 1)[0]);
        return [rows.map((x) => this.decodeRow(fields, x)), fields];
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

        const [rows, fields] = this.decodeCSV(body);

        if (name === 'talent' && this.pro.version === '3.80.1.66991') {
            const patch = (id: number, values: (string | number | (string | number)[])[]) => {
                values[0] = id.toString();
                const row: { [key: string]: string | string[] } = {};
                for (let i = 0; i < fields.length; i++) {
                    const v = values[i];
                    row[fields[i].name] = Array.isArray(v)
                        ? (v as (string | number)[]).map((x) => x.toString())
                        : (v ?? '').toString();
                }
                const idStr = id.toString();
                const idx = rows.findIndex((r) => r['ID'] === idStr);
                if (idx >= 0) {
                    rows[idx] = row;
                } else {
                    rows.push(row);
                }
            };
            patch(1889, ['', '', 8, 0, 2, 301, 9, 0, 0, 0, 0, [0, 0], [1295198, 0, 0, 0, 0, 0, 0, 0, 0], [23714, 0, 0], [0, 0, 0]]);
            patch(2045, ['', '', 7, 0, 3, 301, 9, 0, 0, 0, 0, [0, 0], [47220, 47221, 47223, 0, 0, 0, 0, 0, 0], [0, 0, 0], [0, 0, 0]]);
            patch(23714, ['', '', 8, 0, 1, 301, 9, 0, 0, 0, 0, [0, 0], [1295358, 0, 0, 0, 0, 0, 0, 0, 0], [1676, 0, 0], [0, 0, 0]]);
            patch(1677, ['', '', 7, 0, 2, 301, 9, 0, 0, 0, 0, [0, 0], [30288, 30289, 30290, 30291, 30292, 0, 0, 0, 0], [0, 0, 0], [0, 0, 0]]);
            patch(1678, ['', '', 6, 0, 2, 301, 9, 0, 0, 0, 0, [0, 0], [30293, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0], [0, 0, 0]]);
            patch(1676, ['', '', 7, 1, 1, 301, 9, 0, 0, 0, 0, [0, 0], [30283, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0], [0, 0, 0]]);
            patch(966, ['', '', 5, 0, 2, 301, 9, 0, 0, 0, 0, [0, 0], [17954, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0], [0, 0, 0]]);
        }

        // await Deno.mkdir(path.dirname(p), { recursive: true });
        // await Deno.writeTextFile(p, body);
        return rows;
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
