import fetch from 'cross-fetch';
import { PromisePool } from '@supercharge/promise-pool';
import { LegendManifest } from './actors/declarations/legends.did.d';
import { isJSON } from './util';

const canister = '3-the-empress';
const network = 'ic';
const protocol = 'https';
const host = 'raw.ic0.app';

async function canisterId() {
    if (network === 'ic') {
        return (await import('../canister_ids.json'))[canister].ic;
    } else {
        // return (await import('../.dfx/local/canister_ids.json'))[canister].local;
    };
};

jest.setTimeout(300_000);


// Get supply
const supply = 110;

describe(`${canister}`, () => {

    it('has valid json for every token', async () => {
        const canister = await canisterId();
        const root = `${protocol}://${canister}.${host}`;
        const requests = Array(supply).fill(null).map((x, i) => {
            return fetch(`${root}/${i}.json`)
                .then(async (r) => {
                    const text = await r.text();
                    if (r.status !== 200) console.error(`Token #${i} ${text}`);
                    expect(r.status).toBe(200);
                    return text;
                })
                .then(r => {
                    const isJson = isJSON(r);
                    return expect(isJson).toBe(true);
                })
        });
        await Promise.all(requests);
    });

    it('has a non-zero html app for every token', async () => {
        const canister = await canisterId();
        const root = `${protocol}://${canister}.${host}`;
        const requests = Array(supply).fill(null).map((x, i) => {
            return fetch(`${root}/${i}`)
                .then(r => {
                    expect(r.headers.get('Content-Type')).toBe('text/html');
                    expect(r.status).toBe(200);
                    return r.text()
                })
        });
        await Promise.all(requests);
    });
    
    it('has a non-zero static image for every token', async () => {
        const canister = await canisterId();
        const root = `${protocol}://${canister}.${host}`;
        const requests = Array(supply).fill(null).map((x, i) => {
            return fetch(`${root}/${i}.webp`)
                .then(r => {
                    const filename = r.headers.get('legends-filename');
                    const size = Number(r.headers.get('Content-Length'));
                    if (size < 5_000) console.error(`Invalid static image on token #${i}: ${filename}`);
                    expect(size).toBeGreaterThan(5_000);
                    expect(r.status).toBe(200);
                    return r.text()
                })
        });
        await Promise.all(requests);
    });
    
    it('has a non-zero animated image for every token', async () => {
        const canister = await canisterId();
        const root = `${protocol}://${canister}.${host}`;
        const requests = Array(supply).fill(null).map((x, i) => {
            return fetch(`${root}/${i}.webm`)
                .then(r => {
                    const filename = r.headers.get('legends-filename');
                    const size = Number(r.headers.get('Content-Length'));
                    if (size < 5_000) console.error(`Invalid animated image on token #${i}: ${filename}`);
                    expect(size).toBeGreaterThan(5_000);
                    expect(r.status).toBe(200);
                    return r.text()
                })
        });
        await Promise.all(requests);
    });

    // it('has valid assets for every field in each token json manifest', async () => {
    //     const canister = await canisterId();
    //     const root = `${protocol}://${canister}.${host}`;
    //     const { results, errors } = await PromisePool
    //     .withConcurrency(5)
    //     .for(Array(supply).fill(null))
    //     .process(async (x, i) => {
    //         return await fetch(`${root}/${i}.json`)
    //             .then(r => r.json())
    //             .then((r : LegendManifest) => [...Object.values(r.maps).flat(), ...Object.values(r.views)])
    //             .then(assets => Promise.all(assets.map(asset =>
    //                 asset && fetch(`${root}${asset}`)
    //                 .then(r => {
    //                     // const size = Number(r.headers.get('Content-Length'));
    //                     const status = r.status;
    //                     if (status !== 200) console.error(`Token #${i} Asset ${asset} Status ${status}`);
    //                     // expect(size).toBeGreaterThan(10);
    //                     expect(status).toBe(200);
    //                 })
    //             )))
    //     })
    // });

    it('has every asset from the manifest', async () => {
        // const manifest = await import(`../config/manifests/${canister}.csv`);
        // const c = await canisterId();
        // const root = `${protocol}://${c}.${host}`;
        // console.log(manifest)
    });
});
