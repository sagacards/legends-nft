import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Cap "mo:cap/Cap";

import Admins "../Admins";
import NNS "../NNS/lib";
import NNSTypes "../NNS/types";
import TokenTypes "../Tokens/types";
import Tokens "../Tokens";

module {

    public type State = {
        _Admins     : Admins.Admins;
        _Cap        : Cap.Cap;
        _Nns        : NNS.Factory;
        _Tokens     : Tokens.Factory;
        nextTxId    : TxId;
        purchases   : [(TxId, Purchase)];
        refunds     : [(TxId, Refund)];
        locks       : [(TxId, Lock)];
        // TODO: replace Text with an AccountIdentifier.
        allowlist  : [(AccountIdentifier, Nat8)];
        cid         : Principal;
    };

    public type AccountIdentifier = AccountIdentifier.AccountIdentifier;

    public type TxId = Nat32;

    public type Lock = {
        id          : TxId;
        buyer       : Principal;
        buyerAccount: Text;
        token       : TokenTypes.TokenIndex;
        memo        : Nat64;
        lockedAt    : Time.Time;
    };

    public type Purchase = {
        id          : TxId;
        buyer       : Principal;
        buyerAccount: Text;
        token       : TokenTypes.TokenIndex;
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