import fs from "fs";
import { Principal } from "@dfinity/principal";
import { legend } from "./actors/legends";
import { ActorSubclass, Identity } from "@dfinity/agent";
import { LegendsNFT } from "./actors/declarations/legends.did.d";
import { admin } from "./agent";
import fetch from "cross-fetch";
import { xtc } from "./actors/xtc";
import { balance } from "./actors/ledger";
import { principalToAddress } from "ictool";
import { wicp } from "./actors/wicp";
import { capRoot, capRouter } from "./actors/cap";

/**
 * Retrieve local canister_ids.json file contents.
 * @returns
 */
export function localCanisterIds() {
    return fs.readFileSync("./canister_ids.json", "utf8");
}

/**
 * Parse contents of a canister_ids.json file.
 * @param json JSON string to parse
 */
export function parseCanisterIds(json: string): { [key: string]: string } {
    // Get all canisters
    const canisters: {
        [key: string]: {
            ic: string;
        };
    } = JSON.parse(json);

    // Validate canister_ids.json
    for (const [key, value] of Object.entries(canisters)) {
        if (!("ic" in value)) {
            throw new Error(`Canister ${key} does not have an ic entry`);
        }
        try {
            Principal.fromText(value.ic);
        } catch (e) {
            throw new Error(`Canister ${key} has invalid principal`);
        }
    }

    return Object.entries(canisters).reduce((agg, [key, val]) => {
        return {
            ...agg,
            [key]: val.ic,
        };
    }, {});
}

/**
 * Retrieve CAP root buckets for a set of canisters.
 * @param canisters
 * @returns
 */
export function capCanisters(canisters: { [key: string]: string }) {
    return Promise.all(
        Object.values(canisters).map(
            async (canister) =>
                await capRouter
                    .get_token_contract_root_bucket({
                        canister: Principal.fromText(canister),
                        witness: true,
                    })
                    .then((r) => [canister, r.canister?.[0]?.toText()])
        )
    );
}

export async function capBalances(
    canisters: string[]
): Promise<[string, number][]> {
    return Promise.all(
        canisters.map(async (canister) => {
            if (!canister) throw new Error("CAP canister not found");
            const root = capRoot(canister);
            return [canister, Number(await root.balance())];
        })
    );
}

/**
 * Initialize actors for all canisters in canister data object.
 * @param canisterIds
 * @param identity
 * @returns
 */
export function initCanisterActors(
    canisterIds: { [key: string]: string },
    identity: Identity = admin.key
): {
    [key: string]: {
        id: string;
        actor: ActorSubclass<LegendsNFT>;
    };
} {
    return Object.entries(canisterIds).reduce((agg, [key, val]) => {
        return {
            ...agg,
            [key]: {
                id: val,
                actor: legend(val, identity),
            },
        };
    }, {});
}

// Call balance on each canister

/**
 * Retrieves approximate cycles balance for all canisters. Uses the only exist method of checking root the http endpoint.
 * @param canisters
 */
export async function canisterBalances(canisters: {
    [key: string]: { actor: ActorSubclass<LegendsNFT>; id: string };
}): Promise<{ [key: string]: number }> {
    const balances = await Promise.all(
        Object.entries(canisters).map(async ([key, value]) => {
            const cycles = await cyclesFromExtHttp(value.id);
            return [value.id, cycles];
        })
    );
    return Object.fromEntries(balances);
}

/**
 * Retrieve cycles balance of canister using the standard root Ext Http endpoint.
 * @param canisterId
 * @returns
 */
export async function cyclesFromExtHttp(canisterId: string) {
    const response = await fetch(`https://${canisterId}.raw.ic0.app/`).then(
        (r) => r.text()
    );
    return parseExtHttpCycles(response);
}

/**
 * Parse cycles balance number from root Ext Http response.
 * @param response
 * @returns
 */
export function parseExtHttpCycles(response: string) {
    const cycles = response.match(/Cycle Balance:[ ~]+([0-9]+)T\n/)?.[1];
    return cycles ? Number(cycles) : -1;
}

// Check balance against topup rules, build a list of topups to perform

const topUpThreshold = 5;
const topUpAmount = 10;

export function topUpPlan(balances: { [key: string]: number }) {
    return Object.entries(balances).reduce((agg, [key, value]) => {
        if (value <= topUpThreshold) {
            return [...agg, { canister: key, amount: topUpAmount }];
        } else {
            return agg;
        }
    }, [] as { canister: string; amount: number }[]);
}

// Get management account cycles balance (xtc, icp, wicp)

export async function managementAccountBalanceXtc() {
    return await xtc.balance([]);
}

export async function managementAccountBalanceIcp() {
    return await balance(principalToAddress(admin.key.getPrincipal()));
}

export async function managementAccountBalanceWicp() {
    return await wicp.balanceOf(admin.key.getPrincipal());
}

// Determine if management account has enough cycles to perform topups

/**
 * Determine whether management account has enough cycles to perform topups.
 * @param plan object with canster ID as keys and trillions of cycles as number values
 * @param balance XTC balance of management account in trillions of cycles
 */
export function isPlanFundable(
    plan: { [key: string]: number },
    balance: number
) {
    return Object.values(plan).reduce((agg, val) => agg + val, 0) <= balance;
}

// Buy more cycles if needed

// Determine most efficient XTC trading pool

// If XTC is more efficient than burning ICP, perform necessary trades to exercise optimal trading pool and purchase enough XTC to execute topup plan

// Throw an error if we don't have enough money to topup

// Burn XTC to topup plan

export async function executePlan(plan: { [key: string]: number }) {
    return Promise.all(
        Object.entries(plan).map(async ([key, value]) => {
            await xtc.burn({
                canister_id: Principal.fromText(key),
                amount: BigInt(value * 10 ** 12),
            });
        })
    );
}

// If ICP burning is more efficient than XTC, burn ICP to topup plan

// Throw an error if we don't have enough money to topup
