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

enum HotfixStatus {
    Added = 1,
    Deleted = 2,
    Invalidate = 3,
}

interface HotfixRecord {
    record_id: number;
    build: number;
    table_name: string;
    locale: string;
    status: HotfixStatus;
    data?: any;
}

type TableHotfixMap = { [key: string]: HotfixRecord[] };

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

    private async dataJson(resp: Response) {
        const body = await resp.text();
        const match = [...body.matchAll(/data-page="([^"]+)"/g)];
        if (!match || match.length < 1) {
            throw Error('');
        }

        const data = JSON.parse(Html5Entities.decode(match[0][1]));
        return data;
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

    resolveHotfixesCachePath(table: string, build: number, id: number) {
        const p = path.resolve('.cache', `hotfixes_${table}_${build}_${id}.json`);
        return p;
    }

    async getHotfixesCache(table: string, build: number, id: number) {
        const p = this.resolveHotfixesCachePath(table, build, id);
        if (!await fs.exists(p)) {
            return;
        }
        const body = await Deno.readTextFile(p);
        return JSON.parse(body) as TableHotfixMap;
    }

    async fetchHotfixes(table: string, build: number) {
        table = table.toLowerCase();

        const d: TableHotfixMap = {}
        let page = 1;
        let last = 0;
        let firstId = 0;
        do {
            const url = new URL('https://wago.tools/hotfixes');
            url.searchParams.append('page', page.toString());
            url.searchParams.append('search', build.toString() + ' ' + table);

            const resp = await fetch(url);

            try {

                const data = await this.dataJson(resp);

                if (page === 1) {
                    last = data?.props?.hotfixes?.last_page ?? 0;
                    firstId = data?.props?.hotfixes?.data?.[0]?.id ?? 0;

                    const cd = await this.getHotfixesCache(table, build, firstId);
                    if (cd) {
                        return cd;
                    }

                }
                if (last === 0) {
                    break;
                }

                for (const hotfix of data?.props?.hotfixes?.data ?? []) {
                    if (hotfix.build !== build || hotfix.table_name.toLowerCase() !== table) {
                        continue;
                    }

                    const locale = hotfix.locale.toLowerCase();
                    d[locale] = d[locale] ?? [];
                    d[locale].push(hotfix);
                }

                if (page >= last) {
                    break;
                }

            } catch (e) {
                console.log(e)
            }


            ++page;
        } while (true);

        const cachePath = this.resolveHotfixesCachePath(table, build, firstId);
        await Deno.mkdir(path.dirname(cachePath), { recursive: true });
        await Deno.writeTextFile(cachePath, JSON.stringify(d));

        return d;
    }

    async fetchTable(name: string, locale = 'zhCN', source = 2) {
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

        const hotfixes = await this.fetchHotfixes(name, Number.parseInt(this.pro.version.match(/\.(\d+)$/)?.at(1) ?? '0'));

        if (hotfixes) {
            const added = (id: number, values: (string | number | (string | number)[])[]) => {
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
                    console.log('hotfix updated', name, id);
                } else {
                    rows.push(row);
                    console.log('hotfix added', name, id);
                }
            };

            const deleted = (id: number) => {
                const idStr = id.toString();
                const idx = rows.findIndex((r) => r['ID'] === idStr);
                if (idx >= 0) {
                    rows.splice(idx, 1);
                    console.log('hotfix deleted', name, id);
                } else {
                    console.log('hotfix delete not found', name, id);
                }
            };

            const localeHotfixes = hotfixes[locale]
            if (localeHotfixes) {
                for (const hotfix of localeHotfixes) {
                    if (hotfix.status === HotfixStatus.Added) {
                        added(hotfix.record_id, hotfix.data);
                    } else if (hotfix.status === HotfixStatus.Deleted) {
                        deleted(hotfix.record_id);
                    } else if (hotfix.status === HotfixStatus.Invalidate) {
                        deleted(hotfix.record_id);
                    }
                }
            }
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
