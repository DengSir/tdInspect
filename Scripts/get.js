#!/usr/bin/env node
/**
 * @File   : proxy.js
 * @Author : Dencer (tdaddon@163.com)
 * @Link   : https://dengsir.github.io
 * @Date   : 2022/8/26 15:02:58
 */

const { program } = require("commander");
const got = require("got");
const HttpsProxyAgent = require("hpagent").HttpsProxyAgent;

program.option("-p, --proxy <proxy>");

program.parse(process.argv);

const opts = program.opts();

if (opts.proxy) {
    module.exports = (url) => {
        return got(url, {
            agent: {
                https: new HttpsProxyAgent({
                    keepAlive: true,
                    keepAliveMsecs: 1000,
                    maxSockets: 256,
                    maxFreeSockets: 256,
                    scheduling: "lifo",
                    proxy: opts.proxy,
                }),
            },
        });
    };
} else {
    module.exports = got;
}
