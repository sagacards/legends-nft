import Cap "mo:cap/Cap";
import Ext "mo:ext/Ext";

import Tokens "../Tokens";
import Entrepot "../Entrepot";

module {

    public type State = {
        _Cap        : Cap.Cap;
        _Entrepot   : Entrepot.Factory;
        _Tokens     : Tokens.Factory;
        cid         : Principal;
    };

    // DAB...
    public type Listing = {
        locked : ?Int;
        seller : Principal;
        price  : Nat64;
    };

};