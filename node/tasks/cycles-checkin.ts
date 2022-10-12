import { capRoot } from "../actors/cap";
import {
    canisterBalances,
    capBalances,
    capCanisters,
    initCanisterActors,
    localCanisterIds,
    parseCanisterIds,
} from "../cycles";

async function run() {
    const canisters = parseCanisterIds(localCanisterIds());
    const actors = initCanisterActors(canisters);
    const balances = await canisterBalances(actors);
    console.log("Token canister balances", balances);

    const cap = await capCanisters(canisters);
    const balancesCap = await capBalances(cap.map((c) => c[1] as string));
    console.log(
        "Cap canister balances",
        balancesCap.reduce((agg, [canister, balance]) => {
            return {
                ...agg,
                [canister as string]: `${Number(balance) / 10 ** 12}T`,
            };
        }, {})
    );
}

run();
