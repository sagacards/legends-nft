import Error "mo:base/Error";
import Principal "mo:base/Principal";

import Admins "../src/Admins";
import Types "../src/Admins/types";

let admin = Principal.fromText("2ibo7-dia");
let user  = Principal.fromText("yrxcb-sg7");
let state : Types.State = {
    admins = [admin];
};

let a = Admins.Admins(state);

assert(a.toStable() == state.admins);
assert(a.getAdmins() == state.admins);
assert(a._isAdmin(admin));

assert(not a._isAdmin(user));
assert(not a.isAdmin(admin, user));

a.addAdmin(admin, user);
assert(a._isAdmin(user));
assert(a.isAdmin(admin, user));

a.removeAdmin(user, user);
assert(not a._isAdmin(user));
assert(not a.isAdmin(admin, user));
