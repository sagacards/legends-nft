import Assets "../../Assets";


module Stoic {

    public type State = {
        _Assets : Assets.Assets;
    };

    public type Token = {
        index       : Nat32;
        canister    : [Nat8];
    };

};