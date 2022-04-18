import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Types "types";
import Interface "Interface";

module {

    let LAUNCHPAD_ID = "h7wcp-ayaaa-aaaam-qadqq-cai";

    public class Factory (state : Types.Params) {

        private let lp : Interface.Main = actor(LAUNCHPAD_ID);

        public func launchpadEventCreate (
            caller : Principal,
            event : Interface.Data,
        ) : async Nat {
            assert(state._Admins._isAdmin(caller));
            await lp.createEvent(event);
        };
        
        public func launchpadEventUpdate (
            caller : Principal,
            index : Nat,
            event : Interface.Data,
        ) : async Interface.Result<()> {
            assert(state._Admins._isAdmin(caller));
            await lp.updateEvent(index, event);
        };

        public func withdrawAll(
            caller : Principal,
            to : Interface.AccountIdentifier,
        ) : async Interface.TransferResult {
            assert(state._Admins._isAdmin(caller));
            let amount = await lp.balance();
            await lp.transfer(amount, to);
        };

        public func launchpadTotalAvailable (
            index : Nat,
        ) : Nat {
            state._Tokens._getUnminted().size();
        };
        
        public func launchpadMint (
            caller : Principal,
            to : Principal,
        ) : Result.Result<Nat, Types.MintError> {
            assert(caller == Principal.fromActor(lp));
            let i = switch (state._Tokens._getNextMintIndex()) {
                case (?t) t;
                case _ return #err(#NoneAvailable);
            };
            switch (state._Tokens._mint(i, #principal(to), null)) {
                case (#ok(t)) #ok(Nat32.toNat(i));
                // Might want more flexible or compelte set of variants here for errors, because other projects will be consuming this.
                case (#err(e)) #err(#TryCatchTrap);
            };
        };
    };
};