import { Principal } from "@dfinity/principal";
import { xtc } from "../actors/xtc";

const [, , canister, amount] = process.argv;

async function run() {
    await xtc.burn({
        canister_id: Principal.fromText(canister),
        amount: BigInt(Number(amount) * 10 ** 12),
    });
}

run();
