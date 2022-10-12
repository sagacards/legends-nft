import {
    canisterBalances,
    cyclesFromExtHttp,
    initCanisterActors,
    isPlanFundable,
    localCanisterIds,
    managementAccountBalanceIcp,
    managementAccountBalanceWicp,
    managementAccountBalanceXtc,
    parseCanisterIds,
    parseExtHttpCycles,
    topUpPlan,
} from "./cycles";

const MockCanisters = {
    can1: {
        ic: "rrkah-fqaaa-aaaaa-aaaaq-cai",
    },
    can2: {
        ic: "qsgjb-riaaa-aaaaa-aaaga-cai",
    },
    can3: {
        ic: "qhbym-qaaaa-aaaaa-aaafq-cai",
    },
};

describe("local canister discovery", () => {
    it("parses mock canister_ids.json", () => {
        const canisters = parseCanisterIds(JSON.stringify(MockCanisters));
        expect(canisters.can1).toBe("rrkah-fqaaa-aaaaa-aaaaq-cai");
        expect(canisters.can2).toBe("qsgjb-riaaa-aaaaa-aaaga-cai");
        expect(canisters.can3).toBe("qhbym-qaaaa-aaaaa-aaafq-cai");
    });
    it("rejects mock malformed canister_ids.json (missing ic declaration)", () => {
        expect(() =>
            parseCanisterIds(
                JSON.stringify({
                    ...MockCanisters,
                    can3: {},
                })
            )
        ).toThrowError(`Canister can3 does not have an ic entry`);
    });
    it("rejects mock malformed canister_ids.json (bad principal)", () => {
        expect(() =>
            parseCanisterIds(
                JSON.stringify({
                    ...MockCanisters,
                    can3: {
                        ic: "asdf",
                    },
                })
            )
        ).toThrowError(`Canister can3 has invalid principal`);
    });
    it("parses the real local canister_ids.json", () => {
        const canisters = parseCanisterIds(localCanisterIds());
        for (const [key, value] of Object.entries(canisters)) {
            expect(key).toBeDefined();
            expect(value).toBeDefined();
        }
    });
});

describe("canister actor initialization", () => {
    it("initializes actors for mock canisters", () => {
        const canisters = parseCanisterIds(JSON.stringify(MockCanisters));
        const actors = initCanisterActors(canisters);
        for (const [key, value] of Object.entries(actors)) {
            expect(key).toBeDefined();
            expect(value.id).toBeDefined();
            expect(value.actor).toBeDefined();
            expect(value.actor.getAdmins).toBeDefined();
        }
    });
    it("initializes actors for real canisters", async () => {
        const canisters = parseCanisterIds(localCanisterIds());
        // We don't care about these test canisters
        delete canisters.charlie;
        delete canisters.foxtrot;
        const actors = initCanisterActors(canisters);
        await Promise.all(
            Object.entries(actors).map(async ([key, value]) => {
                expect(key).toBeDefined();
                expect(value.id).toBeDefined();
                expect(value.actor).toBeDefined();
                expect((await value.actor.getAdmins()).length).toBeGreaterThan(
                    0
                );
            })
        );
    });
});

jest.setTimeout(25_000);

describe("canister balance retrieval", () => {
    it("retrieves balance from mock response", () => {
        const response1 = `
            BTC Flower 
            ---
            Cycle Balance:                            ~17T
            Minted NFTs:                              2_009
            Marketplace Listings:                     253
            Sold via Marketplace:                     2_274
            Sold via Marketplace in ICP:              233_589.63 ICP
            Average Price ICP Via Marketplace:        102.72 ICP
            Admin:                                    cbvco-k27pa-dgumq-tjhcq-iqrcx-ayr3z-moywz-jqblc-nvsif-dayv3-4qe`;
        const response2 = `
            Poked Bots - REBORN
            ---
            Cycle Balance:                            ~28T
            Minted NFTs:                              10_000
            Assets:                                   10_000
            Thumbs:                                   10_000
            ---
            Marketplace Listings:                     1_076
            Sold via Marketplace:                     9_383
            Sold via Marketplace in ICP:              135_178.37 ICP
            Average Price ICP Via Marketplace:        14.40 ICP
            ---
            Admin:                                    sensj-ihxp6-tyvl7-7zwvj-fr42h-7ojjp-n7kxk-z6tvo-vxykp-umhfk-wqe`;
        const response3 = `
            Saga Legend #1: The Fool NFT Canister
            ---
            # Minted NFTs: 117
            Cycle Balance: 5T
            ---
            # Marketplace Listings: 31
            # Marketplace Sales: 40
            Marketplace Sale Volume: 71623009998
            Marketplace Largest Sale: 4000000000
            Marketplace Smallest Sale: 200000000
            Marketplace Floor Price: 400000000`;
        expect(parseExtHttpCycles(response1)).toBe(17);
        expect(parseExtHttpCycles(response2)).toBe(28);
        expect(parseExtHttpCycles(response3)).toBe(5);
    });

    it("retrieves balance via ext http", async () => {
        await Promise.all(
            [
                "nges7-giaaa-aaaaj-qaiya-cai",
                "pk6rk-6aaaa-aaaae-qaazq-cai",
                "bzsui-sqaaa-aaaah-qce2a-cai",
                "oeee4-qaaaa-aaaak-qaaeq-cai",
            ].map(async (id) => {
                const balance = await cyclesFromExtHttp(id);
                expect(balance).toBeDefined();
                expect(balance).toBeGreaterThan(-1);
            })
        );
    });

    it("retrieves balance for all canisers", async () => {
        const balances = await canisterBalances(
            initCanisterActors(parseCanisterIds(localCanisterIds()))
        );
        for (const [key, value] of Object.entries(balances)) {
            expect(Number.isInteger(value)).toBeTruthy();
        }
    });
});

describe("top up planning", () => {
    it("plans top ups for mock canisters", () => {
        const plan = topUpPlan({
            "nges7-giaaa-aaaaj-qaiya-cai": 3,
            "pk6rk-6aaaa-aaaae-qaazq-cai": 1,
            "bzsui-sqaaa-aaaah-qce2a-cai": 5,
            "oeee4-qaaaa-aaaak-qaaeq-cai": 10,
        });
        const map = Object.fromEntries(plan.map(Object.values));
        expect(map["nges7-giaaa-aaaaj-qaiya-cai"]).toBe(10);
        expect(map["pk6rk-6aaaa-aaaae-qaazq-cai"]).toBe(10);
        expect(map["bzsui-sqaaa-aaaah-qce2a-cai"]).toBe(10);
        expect(map["oeee4-qaaaa-aaaak-qaaeq-cai"]).toBeUndefined();
    });
});

describe("management account balance", () => {
    it("retrieves xtc balance", async () => {
        const balance = await managementAccountBalanceXtc();
        console.log(
            `Management account balance: ${(Number(balance) / 10 ** 12).toFixed(
                1
            )}T XTC`
        );
        expect(balance).toBeDefined();
    });

    it("retrieves icp balance", async () => {
        const balance = await managementAccountBalanceIcp();
        console.log(
            `Management account balance: ${(Number(balance) / 10 ** 8).toFixed(
                1
            )} ICP`
        );
        expect(balance).toBeDefined();
    });

    it("retrieves wicp balance", async () => {
        const balance = await managementAccountBalanceWicp();
        console.log(
            `Management account balance: ${(Number(balance) / 10 ** 8).toFixed(
                1
            )} wICP`
        );
        expect(balance).toBeDefined();
    });
});

describe("plan fundability", () => {
    it("determines mock plan is fundable", async () => {
        expect(
            isPlanFundable(
                {
                    "nges7-giaaa-aaaaj-qaiya-cai": 10,
                    "pk6rk-6aaaa-aaaae-qaazq-cai": 10,
                    "bzsui-sqaaa-aaaah-qce2a-cai": 10,
                    "oeee4-qaaaa-aaaak-qaaeq-cai": 10,
                },
                50
            )
        ).toBeTruthy();
    });

    it("determines mock plan is NOT fundable", async () => {
        expect(
            isPlanFundable(
                {
                    "nges7-giaaa-aaaaj-qaiya-cai": 10,
                    "pk6rk-6aaaa-aaaae-qaazq-cai": 10,
                    "bzsui-sqaaa-aaaah-qce2a-cai": 10,
                    "oeee4-qaaaa-aaaak-qaaeq-cai": 10,
                },
                10
            )
        ).toBeFalsy();
    });

    it("determines fundability of real plan", async () => {
        const canisters = parseCanisterIds(localCanisterIds());
        // Don't topup test canisters
        delete canisters.charlie;
        delete canisters.foxtrot;
        const balances = await canisterBalances(initCanisterActors(canisters));
        const balance = await managementAccountBalanceXtc();
        const plan: { [key: string]: number } = Object.fromEntries(
            topUpPlan(balances).map(Object.values)
        );
        const fundable = isPlanFundable(plan, Number(balance) / 10 ** 12);
        console.log(
            `Plan to top ${
                Object.values(plan).length
            } canisters with ${Object.values(plan).reduce(
                (agg, i) => agg + i,
                0
            )}T cycles is${
                fundable ? "" : " NOT"
            } fundable with management balance of ${
                Number(balance) / 10 ** 12
            }T XTC`
        );
        expect(fundable).toBeDefined();
    });
});
