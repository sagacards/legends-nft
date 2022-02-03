import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

import Admins "../src/Admins";
import Assets "../src/Assets";
import Types "../src/Assets/types";

let admin = Principal.fromText("2ibo7-dia");
let state : Types.State = {
    assets  = [];
    _Admins = Admins.Admins({ admins = [admin] });
};
let a = Assets.Assets(state);

assert(a._flattenPayload([
    Blob.fromArray([0x00]),
    Blob.fromArray([0x01, 0x02]),
    Blob.fromArray([0x03]),
]) == Blob.fromArray([0x00, 0x01, 0x02, 0x03]));

Debug.print("✅ Assets.mo");
