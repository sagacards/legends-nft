import Array "mo:base/Array";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import AId "mo:principal/AccountIdentifier";

import Allowlist "Allowlist";

let user1   = Principal.fromText("2ibo7-dia");
let user2   = Principal.fromText("yrxcb-sg7");

let l = HashMap.HashMap<AId.AccountIdentifier, Nat8>(0, AId.equal, AId.hash);
l.put(AId.fromPrincipal(user1, null), 2);


let aId = Allowlist.isInAllowlist(user1, l);
assert(aId != null);
    
switch (aId) {
    case (? aId) Allowlist.consumeAllowlist(aId, l);
    case (_)     assert(false);
};

do {
    let aId = Allowlist.isInAllowlist(user1, l);
    assert(aId != null);
};

switch (aId) {
    case (? aId) Allowlist.consumeAllowlist(aId, l);
    case (_)     assert(false);
};

do {
    let aId = Allowlist.isInAllowlist(user1, l);
    assert(aId == null);
};

assert(l.size() == 0);
