/**
 * @File   : util.ts
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/9/26 18:55:36
 */

export function decodeCSV(data: string) {
    const rows = data.split(/[\r\n]+/).filter((x) => x);
    // const headers = rows[0].split(',');
    rows.splice(0, 1);
    return rows.map((x) => x.split(','));
}

export async function fetchData(url: string, searchs: { [k: string]: string }) {
    const u = new URL(url);
    for (const [k, v] of Object.entries(searchs)) {
        u.searchParams.append(k, v);
    }

    const resp = await fetch(u);
    const body = await resp.text();
    return decodeCSV(body);
}
