import { admin, getActor } from "../agent";
import { idlFactory } from "./declarations/xtc.did";
import { XTC } from "./declarations/xtc.did.d";

const XTC_CANISTER_ID = "aanaa-xaaaa-aaaah-aaeiq-cai";

export const xtc = getActor<XTC>(idlFactory, XTC_CANISTER_ID, admin.key);
