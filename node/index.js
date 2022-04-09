const { uniqueNamesGenerator, adjectives, colors, animals } = require('unique-names-generator');
const { idlFactory } = require("./charlie.did.js");
const { getAuthKey, getActor } = require('./agent');
const canisters = require("../canister_ids.json");
const { tokenIdentifier, principalToAccountIdentifier } = require("./ext");
const {idlFactory : nnsIdl } = require("./ledger.did.js");

const admin = ["admin", getAuthKey("admin")];

let users = [];
for (let i = 0; i < 50; i++) {
    users.push([uniqueNamesGenerator({ dictionaries: [adjectives, colors, animals] })]);
}
users = users.map(x => ([x, getAuthKey(x)]));

const actor = getActor(idlFactory, canisters.charlie.ic, admin[1]);

for (const [user, identity] of users) {
    console.log(`Minting ${user}...`);
    actor.mint({ principal: identity.getPrincipal() })
    .then((r) => list(r.ok, identity))
    .catch(console.error)
    .finally();
}

function list (index, identity) {
    console.log(`Listing ${identity.getPrincipal().toText()}`);
    getActor(idlFactory, canisters.charlie.ic, identity).list({
        from_subaccount : [],
        price           : [BigInt(100_000)],
        token           : tokenIdentifier(canisters.charlie.ic, Number(index)),
    })
    .then(() => lock(index))
    .catch(console.error)
    .finally();
};

function lock (index) {
    console.log(`Locking ${index}`);
    actor.lock(
        tokenIdentifier(canisters.charlie.ic, Number(index)),
        BigInt(100_000),
        principalToAccountIdentifier(admin[1].getPrincipal().toText()),
        [],
    )
    .then(r => pay(r.ok))
    .catch(console.error)
    .finally();
};

function pay (address) {
    console.log(`Paying ${address}`);
    getActor(nnsIdl, "ryjl3-tyaaa-aaaaa-aaaba-cai", admin[1])
    .transfer({
        to: Array.from(Buffer.from(address, 'hex')),
        fee : { e8s: BigInt(10_000) },
        memo: 0,
        from_subaccount: [],
        created_at_time: [],
        amount: { e8s: BigInt(100_000) },
    })
    .then(console.log)
    .catch(console.error)
    .finally();
}