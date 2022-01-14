import Admins "../Admins";
import Ledger "../Ledger";
import LedgerTypes "../Ledger/types";
import NNS "../NNS/lib";
import NNSTypes "../NNS/types";
import Time "mo:base/Time";

module {

    public type State = {
        admins      : Admins.Admins;
        nns         : NNS.Factory;
        ledger      : Ledger.Ledger;
        nextTxId    : TxId;
        purchases   : [(TxId, Purchase)];
        refunds     : [(TxId, Refund)];
        locks       : [(TxId, Lock)];
    };

    public type TxId = Nat32;

    public type Lock = {
        id          : TxId;
        buyer       : Principal;
        buyerAccount: Text;
        token       : LedgerTypes.TokenIndex;
        memo        : Nat64;
        lockedAt    : Time.Time;
    };

    public type Purchase = {
        id          : TxId;
        buyer       : Principal;
        buyerAccount: Text;
        token       : LedgerTypes.TokenIndex;
        price       : Nat64;  // ICPe8
        memo        : Nat64;
        lockedAt    : Time.Time;
        closedAt    : Time.Time;
        blockheight : NNSTypes.BlockHeight;
    };

    public type Refund = {
        id          : TxId;
        buyer       : Text;
        transactions: {
            original    : NNSTransaction;
            refund      : NNSTransaction;
        };
    };

    public type NNSTransaction = {
        from        : Text;
        amount      : Nat64; // e8s
        timestamp   : Time.Time;
        memo        : Nat64;
        blockheight : Nat64;
    };

};