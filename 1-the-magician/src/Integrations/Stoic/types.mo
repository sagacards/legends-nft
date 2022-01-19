import Assets "../../Assets";


module Stoic {

    public type State = {
        assets : Assets.Assets;
    };

    public type Token = {
        index       : Nat32;
        canister    : [Nat8];
    };

};