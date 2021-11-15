import Ext "mo:ext/Ext";
import Ledger "../Ledger";

module {

    public type State = {
        ledger : Ledger.Ledger;
    };

    // DAB...
    public type Listing = {
        locked : ?Int;
        seller : Principal;
        price  : Nat64;
    };

    public type TokenExt = (Ext.TokenIndex, ?[Listing], ?[Nat8]);

};