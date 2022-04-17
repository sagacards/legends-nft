import { Identity } from '@dfinity/agent';

import { admin, getActor } from '../agent';
import { Ledger, TransferResult } from './declarations/ledger.did.d';
import { idlFactory as ledgerIdl } from './declarations/ledger.did';


/**
 * Transfer ICP
 * @param to address to receieve funds
 * @param amount amount of ICP to send as e8s
 * @param key identity to sign the message
 * @returns 
 */
export function pay(
    to: string,
    amount: number,
    key: Identity,
): Promise<TransferResult> {
    return getActor<Ledger>(ledgerIdl, "ryjl3-tyaaa-aaaaa-aaaba-cai", key)
        .transfer({
            to: Array.from(Buffer.from(to, 'hex')),
            fee: { e8s: BigInt(10_000) },
            memo: BigInt(0),
            from_subaccount: [],
            created_at_time: [],
            amount: { e8s: BigInt(amount) },
        });
};

/**
 * Retrieve balance of NNS ledger account.
 * @param account account to retrieve balance
 * @param key signing identity
 * @returns ICP account balance as e8s
 */
export function balance(
    account: string,
    key: Identity = admin.key,
): Promise<number> {
    return getActor<Ledger>(ledgerIdl, "ryjl3-tyaaa-aaaaa-aaaba-cai", key)
        .account_balance({ account: Array.from(Buffer.from(account, 'hex')) })
        .then(r => Number(r.e8s));
};