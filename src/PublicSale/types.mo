import Time "mo:base/Time";

import Ledger "../Ledger";
import LedgerTypes "../Ledger/types";
import NNSNotifyTypes "../NNSNotify/types";

module {

    public type State = {
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
        memo        : NNSNotifyTypes.Memo;
        lockedAt    : Time.Time;
    };

    public type Purchase = {
        id          : TxId;
        buyer       : Principal;
        token       : LedgerTypes.TokenIndex;
        price       : Nat64;  // ICPe8
        memo        : NNSNotifyTypes.Memo;
        lockedAt    : Time.Time;
        closedAt    : Time.Time;
    };

};