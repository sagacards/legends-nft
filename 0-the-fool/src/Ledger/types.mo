// 3rd Party Imports
import Ext "mo:ext/Ext";

// Project Imports

import Admins "../Admins";
import Assets "../Assets";

// Module Imports

module Ledger {

    public type State = {
        admins  : Admins.Admins;
        assets  : Assets.Assets;
        ledger  : [?Token];
        legends : [Legend];
        supply  : Nat;
    };

    public type Legend = {
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