import Ledger "../Ledger";
import LedgerTypes "../Ledger/types";
import NNS "../NNS/lib";
import Time "mo:base/Time";

module {

    public type State = {
        nns         : NNS.Factory;
        ledger      : Ledger.Ledger;
        nextTxId    : TxId;
        purchases   : [(TxId, Purchase)];
        failed      : [(TxId, Purchase)];
        locks       : [(TxId, Lock)];
    };

    public type TxId = Nat32;

    public type Lock = {
        id          : TxId;
        buyer       : Principal;
        token       : LedgerTypes.TokenIndex;
        memo        : Nat64;
        lockedAt    : Time.Time;
    };

    public type Purchase = {
        id          : TxId;
        buyer       : Principal;
        token       : LedgerTypes.TokenIndex;
        price       : Nat64;  // ICPe8
        memo        : Nat64;
        lockedAt    : Time.Time;
        closedAt    : Time.Time;
    };

};