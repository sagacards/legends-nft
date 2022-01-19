import fetch from 'node-fetch';

/*
The fact of the matter (as of 2021-12-06) is that onchain transactions will require processing refunds manually for cases where a user sent ICP but did not send a payment notification to the canister.

This script uses the Rosetta API to help identify such payments as the delta between NNS ledger transactions and the NFT canister payments ledger. Here we pull all sent to the NFT canister, which we can then pass to the NFT canister for processing. The canister calls will be done in dfx / zsh, this script simply pulls together the NNS ledger transaction data.

We are interested in an transactions sent the NFT canister.
*/

const start = process.argv[2] || 0;
const end = process.argv[3] || 99999999999999999999;

const CanisterAccount = '39385700a813375477ca0d044b65593272283650d23c0ac0acbc6e48cad5e6fc';
const CanisterPrincipal = 'nges7-giaaa-aaaaj-qaiya-cai';

// Rosetta is super picky. If a request isn't properly formed it will return a blank response.
const API = 'https://rosetta-api.internetcomputer.org/search/transactions';
// 'content-type: application/json;charset=UTF-8'
const data = {
    "network_identifier": {
        "blockchain": "Internet Computer",
        "network": "00000000000000020101",
    },
    "account_identifier": {
        "address": CanisterAccount,
    },
}

fetch(API, {
    method: 'POST',
    headers: {
        'content-type': 'application/json;charset=UTF-8',
    },
    body: JSON.stringify(data),
})
.then(r => r.json())
.then(r => {
    return r.transactions
        .filter(x => x.transaction.operations[1].account.address === CanisterAccount
            && x.transaction.operations[1].status === 'COMPLETED'
            && x.transaction.metadata.block_height > 1_646_947 /* Last known test transaction block */)
        .map(x => ({
            from: x.transaction.operations[0].account.address,
            amount: x.transaction.operations[1].amount.value,
            timestamp: x.transaction.metadata.timestamp,
            memo: x.transaction.metadata.memo,
            blockheight: x.transaction.metadata.block_height,
        }))
        .sort((a, b) => a.timestamp - b.timestamp)
        .slice(start, end)
        .reduce((agg, x) => `${agg}
record {
    from        = "${x.from}";
    amount      = ${x.amount} : nat64;
    timestamp   = ${x.timestamp} : int;
    memo        = ${x.memo} : nat64;
    blockheight = ${x.blockheight} : nat64;
};`, '');
})
.then(console.log)