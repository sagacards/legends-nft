import Array "mo:base/Array";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Interface "mo:bazaar/Interface";
import Events "mo:bazaar/Events";
import Ledger "mo:bazaar/Ledger";

import TokenTypes "../Tokens/types";
import Types "types";

module {

    let LAUNCHPAD_ID = "h7wcp-ayaaa-aaaam-qadqq-cai";

    public class Factory (state : Types.Params) {

        private let lp : Interface.Main = actor(LAUNCHPAD_ID);

        public func launchpadEventCreate (
            caller : Principal,
            event : Events.Data,
        ) : async Nat {
            assert(state._Admins._isAdmin(caller));
            await lp.createEvent(event);
        };
        
        public func launchpadEventUpdate (
            caller : Principal,
            index : Nat,
            event : Events.Data,
        ) : async Events.Result<()> {
            assert(state._Admins._isAdmin(caller));
            await lp.updateEvent(index, event);
        };

        public func withdrawAll(
            caller : Principal,
            to : Blob,
        ) : async Ledger.TransferResult {
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
        ) : async Result.Result<Nat, Interface.MintError> {
            assert(caller == Principal.fromActor(lp));
            switch (await state._Tokens.mint(state.cid, #principal(to))) {
                case (#ok(t)) #ok(t);
                case (#err(e)) #err(#NoneAvailable);
            };
        };

        public func launchpadBalanceOf (
            user : Principal
        ) : Nat {
            let u = AccountIdentifier.toText(AccountIdentifier.fromPrincipal(user, null));
            Array.filter<?TokenTypes.Token>(state._Tokens.read(null), func (t) {
                switch (t) {
                    case (?t) t.owner == u;
                    case _ false;
                };
            }).size();
        };
    };
};