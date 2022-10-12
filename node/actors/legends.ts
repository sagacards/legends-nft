import { Identity } from "@dfinity/agent";
import { encodeTokenIdentifier, principalToAddress } from "ictool";

import { getActor, admin } from "../agent";
import { idlFactory as legendsIdl } from "./declarations/legends.did";
import { AccountIdentifier, LegendsNFT } from "./declarations/legends.did.d";

import canisters from "../../canister_ids.json";

const actor = getActor<LegendsNFT>(legendsIdl, canisters.charlie.ic, admin.key);

export function legend(canisterId: string, identity: Identity) {
    return getActor<LegendsNFT>(legendsIdl, canisterId, identity);
}

/**
 * Mint an NFT.
 * @param to principal to receive the token.
 * @returns the index of the token that was minted
 */
export function mint(to: Identity): Promise<number> {
    return getActor<LegendsNFT>(legendsIdl, canisters.charlie.ic, admin.key)
        .mint({ principal: to.getPrincipal() })
        .then((r) => {
            // @ts-ignore: variant typesissue
            return Number(r.ok);
        });
}

/**
 * List an NFT for marketplace sale.
 * @param token token index to be listed
 * @param price price in e8s to list the token for
 * @param key identity to sign the message
 * @returns the index of the token which was listed
 */
export function list(
    token: number,
    price: number,
    key: Identity
): Promise<number> {
    return getActor<LegendsNFT>(legendsIdl, canisters.charlie.ic, key)
        .list({
            from_subaccount: [],
            price: [BigInt(price)],
            token: encodeTokenIdentifier(canisters.charlie.ic, Number(token)),
        })
        .then(() => token);
}

/**
 * Request a purchase lock on a marketplace listed NFT.
 * @param token index of the token to lock
 * @param price price to pay for the token
 * @param key identity to sign the mssage
 * @returns payment address to send ICP to
 */
export function lock(
    token: number,
    price: number,
    key: Identity
): Promise<AccountIdentifier> {
    return getActor<LegendsNFT>(legendsIdl, canisters.charlie.ic, key)
        .lock(
            encodeTokenIdentifier(canisters.charlie.ic, Number(token)),
            BigInt(price),
            principalToAddress(admin.key.getPrincipal()),
            []
        )
        .then((r) => {
            // @ts-ignore: variant types issue
            return r.ok;
        });
}

/**
 * Retrieve the current size of the disbursement queue.
 * @returns size of the disbursement queue
 */
export function disbursementQueueSize(): Promise<Number> {
    return getActor<LegendsNFT>(legendsIdl, canisters.charlie.ic, admin.key)
        .disbursementQueueSize()
        .then((r) => Number(r));
}

/**
 * Retrieve current number of outstanding disbursement jobs.
 * @returns number of outstanding disbursement jobs
 */
export function disbursementPendingCount(): Promise<number> {
    return getActor<LegendsNFT>(legendsIdl, canisters.charlie.ic, admin.key)
        .disbursementPendingCount()
        .then((r) => Number(r));
}
