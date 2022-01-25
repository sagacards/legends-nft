import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Random "mo:base/Random";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Ext "mo:ext/Ext";
import Prim "mo:prim";

import AssetTypes "../Assets/types";
import Types "types";


module {

    public class Factory (state : Types.State) {


        ////////////////////////
        // Utils / Internals //
        //////////////////////


        public func _getNextMintIndex () : ?Nat {
            var i : Nat = 0;
            for (v in ledger.vals()) {
                if (v == null) return ?i;
                i += 1;
            };
            return null;
        };

        // Turn a principal and a subaccount into an uppercase textual account id.
        func _accountId(
            principal   : Principal,
            subaccount  : ?Ext.SubAccount,
        ) : Ext.AccountIdentifier {
            let aid = AccountIdentifier.fromPrincipal(principal, subaccount);
            Text.map(AccountIdentifier.toText(aid), Prim.charToUpper);
        };

        public func _getUnminted () : [Ext.TokenIndex] {
            let unminted = Buffer.Buffer<Ext.TokenIndex>(0);
            var i : Nat32 = 17;
            while (Nat32.toNat(i) < Nat16.toNat(state.supply)) {
                if (Option.isNull(ledger[Nat32.toNat(i)])) {
                    unminted.add(i);
                };
                i += 1;
            };
            return unminted.toArray();
        };

        public func _getMinted () : [Ext.TokenIndex] {
            let minted = Buffer.Buffer<Ext.TokenIndex>(0);
            var i : Nat32 = 0;
            while (Nat32.toNat(i) < Nat16.toNat(state.supply)) {
                if (not Option.isNull(ledger[Nat32.toNat(i)])) {
                    minted.add(i);
                };
                i += 1;
            };
            return minted.toArray();
        };

        // Get a random unminted token index.
        // Excludes non general sale tokens
        public func _getRandomMintIndex (
            exclude : ?[Ext.TokenIndex],
        ) : async ?Ext.TokenIndex {
            var i : Nat32 = 17;
            let unminted = Buffer.Buffer<Ext.TokenIndex>(0);
            label l while (Nat32.toNat(i) < Nat16.toNat(state.supply)) {
                switch (exclude) {
                    case (?ex) {
                        var msg = "Ignoring vals: ";
                        for (v in ex.vals()) {
                            msg := msg # Nat32.toText(v) # ", ";
                        };
                        if (not Option.isNull(Array.find<Ext.TokenIndex>(ex, func (a) { a == i }))) {
                            i += 1;
                            continue l;
                        }
                    };
                    case _ ();
                };
                if (Option.isNull(ledger[Nat32.toNat(i)])) {
                    unminted.add(i);
                };
                i += 1;
            };
            let size = unminted.size();
            if (size == 0) {
                return null;
            };
            var token : ?Ext.TokenIndex = null;
            i := 0;
            let random = Random.Finite(await Random.blob());
            while (Option.isNull(token)) {
                switch ((random.coin(), random.coin())) {
                    case ((?a, ?b)) {
                        if (a and b) {
                            token := ?unminted.get(Nat32.toNat(i));
                        } else {
                            i += 1;
                        };
                    };
                    case _ token := ?unminted.get(0);
                };
                if (Nat32.toNat(i) >= size) i := 0;
            };
            token;
        };

        public func _getLegend (i : Nat) : Types.Legend {
            legends[i];
        };

        public func _getOwner (i : Nat) : ?Types.Token {
            ledger[i];
        };

        public func _isOwner (
            caller      : Ext.AccountIdentifier,
            tokenIndex  : Ext.TokenIndex,
        ) : Bool {
            let token = switch (_getOwner(Nat32.toNat(tokenIndex))) {
                case (?t) {
                    Text.map(caller, Prim.charToUpper) == Text.map(t.owner, Prim.charToUpper);
                };
                case _ false;
            };
        };

        public func _mint (
            tokenIndex  : Ext.TokenIndex,
            to          : Ext.User,
            subaccount  : ?Ext.SubAccount,
        ) : Result.Result<(), Text> {
            switch (ledger[Nat32.toNat(tokenIndex)]) {
                case (?_) #err("Already minted");
                case _ {
                    ledger[Nat32.toNat(tokenIndex)] := ?{
                        createdAt = Time.now();
                        owner = switch (to) {
                            case (#address(a)) a;
                            case (#principal(p)) _accountId(p, subaccount)
                        };
                        txId = "N/A";
                    };
                    #ok();
                };
            }
        };


        ////////////
        // State //
        //////////


        var ledger : [var ?Types.Token] = Array.init(Nat16.toNat(state.supply), null);
        var legends : [Types.Legend] = [];

        // Provision ledger from stable state
        ledger := Array.thaw(state.tokens);

        // Provision legends from stable state
        legends := state.legends;

        public func toStable () : {
            tokens  : [?Types.Token];
            legends : [Types.Legend];
        } {
            {
                tokens = Array.freeze(ledger);
                legends = legends;
            }
        };


        ////////////////
        // Admin API //
        //////////////


        // @auth: admin
        public func mint (
            caller  : Principal,
            to      : Ext.User,
        ) : async Result.Result<(Nat), Text> {
            assert(state._Admins._isAdmin(caller));
            switch (_getNextMintIndex()) {
                case (?i) {

                    // Mint the NFT
                    ledger[i] := ?{
                        createdAt = Time.now();
                        owner = Ext.User.toAccountIdentifier(to);
                        txId = "N/A";
                    };

                    // Insert transaction history event.
                    ignore await state._Cap.insert({
                        caller;
                        operation = "mint";
                        details = [
                            ("token", #Text(tokenId(state.cid, Nat32.fromNat(i)))),
                            ("to", #Text(Ext.User.toAccountIdentifier(to))),
                            // TODO: Add price
                        ];
                    });
                    #ok(i);
                };
                case _ #err("No more supply.");
            }
        };

        // @auth: admin
        public func configureLegends (
            caller  : Principal,
            conf    : [Types.Legend],
        ) : Result.Result<(), Text> {
            assert(state._Admins._isAdmin(caller));
            if (conf.size() != Nat16.toNat(state.supply)) {
                return #err(
                    "Must include configuration for " #
                    Nat.toText(Nat16.toNat(state.supply)) #
                    " legends. Received " #
                    Nat.toText(conf.size())
                );
            };
            legends := conf;
            #ok();
        };

        // Download a backup copy of the ledger.
        // @auth: admin
        public func backup (
            caller : Principal,
        ) : [?Types.Token] {
            assert(state._Admins._isAdmin(caller));
            Array.freeze(ledger);
        };

        // Restore the ledger from a backup.
        // @auth: admin
        public func restore (
            caller  : Principal,
            data    : [?Types.Token],
        ) : Result.Result<(), Text> {
            ledger := Array.thaw(data);
            #ok();
        };


        /////////////////
        // Public API //
        ///////////////


        public func read (index : ?Nat) : [?Types.Token] {
            switch (index) {
                case (?i) [ledger[i]];
                case _ Array.freeze(ledger);
            };
        };


        public func nfts (index : ?Nat) : [Types.Legend] {
            switch (index) {
                case (?i) [legends[i]];
                case _ legends;
            };
        };


        public func transfer (
            tokenIndex  : Ext.TokenIndex,
            caller      : Ext.AccountIdentifier,
            to          : Ext.AccountIdentifier,
        ) : () {
            assert (_isOwner(caller, tokenIndex));
            let i = Nat32.toNat(tokenIndex);
            let token = ledger[i];
            ledger[i] := ?{
                createdAt = switch (token) {
                    case (?t) t.createdAt;
                    case _ Time.now();
                };
                owner = to;
                txId = "N/A";
            };
        };

        public func tokenId(
            canister : Principal,
            index : Ext.TokenIndex,
        ) : Ext.TokenIdentifier {
            Ext.TokenIdentifier.encode(canister, index);
        };

    };

};