import { admin, getActor } from "../agent";
import { idlFactory } from "./declarations/wicp.did";
import { WICP } from "./declarations/wicp.did.d";

const WICP_CANISTER_ID = "utozz-siaaa-aaaam-qaaxq-cai";

export const wicp = getActor<WICP>(idlFactory, WICP_CANISTER_ID, admin.key);
