const { uniqueNamesGenerator, adjectives, colors, animals } = require('unique-names-generator');
const { getAuthKey, getActor } = require('./agent');
const { tokenIdentifier, principalToAccountIdentifier } = require("./ext");
const { idlFactory } = require("./charlie.did.js");
const { idlFactory : nnsIdl } = require("./ledger.did.js");
const canisters = require("../canister_ids.json");

const userCount = 100;
const price = 40_000;
const admin = { name: "admin", key: getAuthKey("admin") };

const commisions = 'ea6e340b18837860b1d9f353af06d459af55c74d97ef3ac024c2a42778e3e030';
const marketplace = 'c7e461041c0c5800a56b64bb7cefc247abc0bbbb99bd46ff71c64e92d9f5c2f9';

let users = [];
for (let i = 0; i < userCount; i++) {
    const name = uniqueNamesGenerator({ dictionaries: [adjectives, colors, animals] });
    users.push({ name, key: getAuthKey(name) });
}

Promise.all(users.map(({ name, key }) => saleTest(name, key)))
.then(r => {
    awaitQueue()
    .then(() => r.forEach(i => verifyBalance(...i)));
})

// balance(commisions, admin.key).then(console.log)

async function saleTest (name, key) {
    console.info(`E2E Sale Test ${name}...`);
    const index = await mint(key);

    console.info(`Listing ${name} (${index})...`);
    await list(index, key);
    
    console.info(`Locking ${name} (${index})...`);
    const paymentAddress = await lock(index);
    
    console.info(`Transferring ${name} ${price} ${paymentAddress}`);
    await pay(paymentAddress);

    return [name, paymentAddress, key]
};

async function awaitQueue () {
    console.info(`Waiting on queue`);
    let queueComplete = false;
    await sleep(5_000);
    const start = new Date();
    while (!queueComplete) {
        const queue = await queueSize();
        queueComplete = queue === 0;
        await sleep(1_000);
        console.log('Queue size', queue);
    };
    let finalized = false;
    while (!finalized) {
        const queue = await pendingSize();
        finalized = queue === 0;
        await sleep(1_000);
        console.log('Finishing', queue);
    };
    console.info(`Done in ${((new Date().getTime() - start.getTime()) / 1000).toFixed(2)}s`);
    await sleep(3_000);
};

async function verifyBalance (name, paymentAddress, key) {
    console.info(`Validating balances ${name} ${paymentAddress}`);
    const b = await balance(paymentAddress, key);
    if (b === 0) {
        console.info(`${name} OK!`)
    } else {
        console.info(`${name} ERR! (${b})`);
    }
};

function mint (key) {
    return getActor(idlFactory, canisters.charlie.ic, admin.key)
    .mint({ principal: key.getPrincipal() })
    .then(r => r.ok);
};

function list (index, key) {
    return getActor(idlFactory, canisters.charlie.ic, key).list({
        from_subaccount : [],
        price           : [BigInt(price)],
        token           : tokenIdentifier(canisters.charlie.ic, Number(index)),
    })
    .then(() => index);
};

function lock (index, key = admin.key) {
    return getActor(idlFactory, canisters.charlie.ic, key).lock(
        tokenIdentifier(canisters.charlie.ic, Number(index)),
        BigInt(price),
        principalToAccountIdentifier(admin.key.getPrincipal().toText()),
        [],
    )
    .then(r => r.ok);
};

function pay (to, amount = price, key = admin.key) {
    return getActor(nnsIdl, "ryjl3-tyaaa-aaaaa-aaaba-cai", key)
    .transfer({
        to: Array.from(Buffer.from(to, 'hex')),
        fee : { e8s: BigInt(10_000) },
        memo: 0,
        from_subaccount: [],
        created_at_time: [],
        amount: { e8s: BigInt(amount) },
    });
};

function queueSize () {
    return getActor(idlFactory, canisters.charlie.ic, admin.key)
    .disbursementQueueSize()
    .then(r => Number(r))
};

function pendingSize () {
    return getActor(idlFactory, canisters.charlie.ic, admin.key)
    .disbursementPendingCount()
    .then(r => Number(r))
};

function sleep (ms) {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
};

function balance (account, key) {
    return getActor(nnsIdl, "ryjl3-tyaaa-aaaaa-aaaba-cai", key)
    .account_balance({ account: Array.from(Buffer.from(account, 'hex')) })
    .then(r => Number(r.e8s));
};