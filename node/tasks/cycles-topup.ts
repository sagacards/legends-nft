import {
    canisterBalances,
    capBalances,
    capCanisters,
    executePlan,
    initCanisterActors,
    isPlanFundable,
    localCanisterIds,
    managementAccountBalanceXtc,
    parseCanisterIds,
    topUpPlan,
} from "../cycles";

async function run() {
    const canisters = parseCanisterIds(localCanisterIds());
    delete canisters.charlie;
    delete canisters.foxtrot;
    console.log(canisters);
    const actors = initCanisterActors(canisters);
    const balances = await canisterBalances(actors);
    console.log(balances);
    const capCans = await capCanisters(canisters);
    const _capBalances = await capBalances(capCans.map((c) => c[1] as string));
    console.log(_capBalances.map(([k, v]) => [k, v / 10 ** 12]));
    const plan: { [key: string]: number } = Object.fromEntries(
        topUpPlan({
            ...balances,
            ...Object.fromEntries(
                _capBalances.map(([k, v]) => [k, v / 10 ** 12])
            ),
        }).map(Object.values)
    );
    console.log(plan);
    const balanceXtc = await managementAccountBalanceXtc();
    console.log(balanceXtc);
    const fundible = isPlanFundable(plan, Number(balanceXtc) / 10 ** 12);
    console.log(
        `Plan to top ${
            Object.values(plan).length
        } canisters with ${Object.values(plan).reduce(
            (agg, i) => agg + i,
            0
        )}T cycles is ${
            fundible ? "" : " NOT"
        } fundable with management balance of ${
            Number(balanceXtc) / 10 ** 12
        }T XTC`
    );
    if (!fundible) {
        throw new Error("Can't fund plan");
    }
    await executePlan(plan);
    console.log("done");
}

run();
