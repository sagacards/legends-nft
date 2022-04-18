import * as csv from '@fast-csv/parse';
import fetch from 'cross-fetch';
import { isJSON } from './util';

const canister = '2-the-high-priestess';
const network = 'ic';
const protocol = 'https';
const host = 'raw.ic0.app';

async function canisterId() {
    if (network === 'ic') {
        return (await import('../canister_ids.json'))[canister].ic;
    } else {
        return (await import('../.dfx/local/canister_ids.json'))[canister].local;
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
                .then(r => r.text())
                .then(r => expect(isJSON(r)).toBe(true))
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
                    const size = Number(r.headers.get('Content-Length'));
                    if (size < 5_000) console.error(`Invalid static image on token #${i}`);
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
                    const size = Number(r.headers.get('Content-Length'));
                    if (size < 5_000) console.error(`Invalid animated image on token #${i}`);
                    expect(size).toBeGreaterThan(5_000);
                    expect(r.status).toBe(200);
                    return r.text()
                })
        });
        await Promise.all(requests);
    });

    it('has every asset from the manifest', async () => {
        // const manifest = await import(`../config/manifests/${canister}.csv`);
        // const c = await canisterId();
        // const root = `${protocol}://${c}.${host}`;
        // console.log(manifest)
    });
});
