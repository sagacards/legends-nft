import Ext "mo:ext/Ext";

import Cap "mo:cap/Cap";

import Admins "../Admins";
import Assets "../Assets";


module {

    public type LocalStableState = {
        tokens      : [?Token];
        metadata    : [Metadata];
        isShuffled  : Bool;
    };

    public type State = {
        _Admins     : Admins.Admins;
        _Assets     : Assets.Assets;
        _Cap        : Cap.Cap;
        tokens      : [?Token];
        metadata    : [Metadata];
        isShuffled  : Bool;
        supply      : Nat16;
        cid         : Principal;
    };

    public type Metadata = {
        back    : Text;
        border  : Text;
        ink     : Text;
    };

    public type TokenIndex = Nat32;

    public type Token = {
        createdAt  : Int;
        owner      : Ext.AccountIdentifier;
        txId       : Text;
    };

};