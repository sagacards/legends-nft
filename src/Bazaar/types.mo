import Result "mo:base/Result";

import Admins "../Admins";
import Tokens "../Tokens";

import Interface "mo:bazaar/Interface";

module {

    public type State = {};
    public type Deps = {
        _Admins : Admins.Admins;
        _Tokens : Tokens.Factory;
        cid     : Principal;
    };
    public type Params = State and Deps;

};
