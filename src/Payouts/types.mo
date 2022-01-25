import Time "mo:base/Time";

import Ext "mo:ext/Ext";

import Admin "../Admins/lib";
import NNS "../NNS";
import NNSTypes "../NNS/types";
import Payments "../Payments";
import Tokens "../Tokens";

module {

    public type State = { 
        _Admins     : Admin.Admins;
        _Tokens     : Tokens.Factory;
        _Nns        : NNS.Factory;
        _Payments   : Payments.Factory;
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