// 3rd Party Imports


// Project Imports

import Admins "../Admins";
import Assets "../Assets";

// Module Imports

module Ledger {

    public type State = {
        admins  : Admins.Admins;
        assets  : Assets.Assets;
        ledger  : [?Principal];
        legends : [Legend];
    };

    public type MintingStage = { #admins; #community; #general; };

    public type Legend = {
        back    : Text;
        border  : Text;
    };

};