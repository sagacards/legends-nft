import { Identity } from '@dfinity/agent';
import { randomUser } from './agent';
import { sleep } from './util';
import { mint, list, lock, disbursementQueueSize, disbursementPendingCount } from './actors/legends';
import { pay, balance } from './actors/ledger';


// TODO: Make this work local (configurable network, mock ledger, etc)
const userCount = 100;
const price = 40_000;

const users = Array(userCount).fill(null).map(randomUser);

jest.setTimeout(300_000);

describe('marketplace protocol', () => {

    it('works', async () => {
        await Promise.all(users.map(({ name, key }) => saleTest(name, key)))
            .then(r => {
                awaitQueue()
                    .then(() => r.forEach(i => verifyBalance(...i)));
            })
    });
});


async function saleTest(
    name: string,
    key: Identity,
) : Promise<[string, string, Identity]> {
    console.info(`E2E Sale Test ${name}...`);
    const index = await mint(key);

    console.info(`Listing ${name} (${index})...`);
    await list(index, price, key);

    console.info(`Locking ${name} (${index})...`);
    const paymentAddress = await lock(index, price, key);

    console.info(`Transferring ${name} ${price} ${paymentAddress}`);
    await pay(paymentAddress, price, key);

    return [name, paymentAddress, key]
};

async function awaitQueue() : Promise<void> {
    console.info(`Waiting on queue`);
    let queueComplete = false;
    await sleep(5_000);
    const start = new Date();
    while (!queueComplete) {
        const queue = await disbursementQueueSize();
        queueComplete = queue === 0;
        await sleep(1_000);
        console.log('Queue size', queue);
    };
    let finalized = false;
    while (!finalized) {
        const queue = await disbursementPendingCount();
        finalized = queue === 0;
        await sleep(1_000);
        console.log('Finishing', queue);
    };
    console.info(`Done in ${((new Date().getTime() - start.getTime()) / 1000).toFixed(2)}s`);
    await sleep(3_000);
};

async function verifyBalance(
    name: string,
    paymentAddress: string,
    key: Identity,
) : Promise<void> {
    console.info(`Validating balances ${name} ${paymentAddress}`);
    const b = await balance(paymentAddress, key);
    if (b === 0) {
        console.info(`${name} OK!`)
    } else {
        console.info(`${name} ERR! (${b})`);
    }
};
