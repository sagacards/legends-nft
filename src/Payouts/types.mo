import Admin "../Admins/lib";
import Ext "mo:ext/Ext";
import Ledger "../Ledger";
import NNS "../NNS";
import NNSTypes "../NNS/types";
import Payments "../Payments";
import Time "mo:base/Time";

module {

    public type State = { 
        admins      : Admin.Admins;
        ledger      : Ledger.Ledger;
        nns         : NNS.Factory;
        payments    : Payments.Factory;
    };

    public type Manifest = {
        timestamp   : Time.Time;
        payouts     : [Payout];
        amount      : NNSTypes.ICP;
    };

    public type Payout = {
        recipient   : Ext.AccountIdentifier;
        amount      : Nat64;
        paid        : Bool;
        blockheight : ?NNSTypes.BlockHeight;
    };

};