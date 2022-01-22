import Cap "mo:cap/Cap";
import Ext "mo:ext/Ext";

import Tokens "../Tokens";

module {

    public type State = {
        cap     : Cap.Cap;
        tokens  : Tokens.Factory;
        _canisterPrincipal  : () -> Principal;
    };

    // DAB...
    public type Listing = {
        locked : ?Int;
        seller : Principal;
        price  : Nat64;
    };

};