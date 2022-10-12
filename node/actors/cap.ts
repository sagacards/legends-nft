import { admin, getActor } from "../agent";
import { CapRouter } from "./declarations/cap-router.did.d";
import { idlFactory as routerIDL } from "./declarations/cap-router.did";
import { CapRoot } from "./declarations/cap-root.did.d";
import { idlFactory as rootIDL } from "./declarations/cap-root.did";

export const CAP_CANISTER_ID = "lj532-6iaaa-aaaah-qcc7a-cai";
export const capRouter = getActor<CapRouter>(
    routerIDL,
    CAP_CANISTER_ID,
    admin.key
);

export const capRoot = (id: string) =>
    getActor<CapRoot>(rootIDL, id, admin.key);
