import Cap "mo:cap/Cap";
import Ext "mo:ext/Ext";

import Tokens "../Tokens";

module {

    public type State = {
        _Cap    : Cap.Cap;
        _Tokens : Tokens.Factory;
        cid     : Principal;
    };

    // DAB...
    public type Listing = {
        locked : ?Int;
        seller : Principal;
        price  : Nat64;
    };

};