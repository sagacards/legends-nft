import Result "mo:base/Result";

import Admins "../Admins";
import Tokens "../Tokens";

import Interface "Interface";

module {

    public type State = {};
    public type Deps = {
        _Admins : Admins.Admins;
        _Tokens : Tokens.Factory;
    };
    public type Params = State and Deps;

    // --

    public type MintError = {
        /// Indicates that no more NFTs are available.
        #NoneAvailable;
        /// Indicates that an external services trapped...
        #TryCatchTrap;
    };

    public type Interface = actor {
        // 🛑 NFT ADMIN RESTRICTED

        // Creates a new event and returns the storage index.
        launchpadEventCreate : shared (event : Interface.Data) -> async Nat;
        // Overwrites the event at the given storage index.
        launchpadEventUpdate : shared (index : Nat, event : Interface.Data) -> async Interface.Result<()>;

        // 🚀 LAUNCHPAD RESTRICTED

        // Returns the total available nfts.
        launchpadTotalAvailable : query (index : Nat) -> async Nat;
        // Allows the launchpad to mint a (random) NFT to the given principal.
        // @returns : the NFT id.
        // @traps   : not authorized.
        // @err     : no nfts left...
        launchpadMint : shared (to : Principal) -> async Result.Result<Nat, MintError>;
    };
};
