// 3rd Party Imports

import AccountIdentifier "mo:principal/AccountIdentifier";
import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Ext "mo:ext/Ext";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Prim "mo:prim";
import Random "mo:base/Random";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

// Project Imports

import AssetTypes "../Assets/types";

// Module Imports

import Types "types";


module {

    public class Ledger (state : Types.State) {


        /////////////
        // Config //
        ///////////


        public let NRI = [
            ("back-fate"          , 0.0000),
            ("back-bordered-saxon", 0.5283),
            ("back-worn-saxon"    , 0.9434),
            ("back-saxon"         , 1.0000),
            ("border-thin"        , 0.0000),
            ("border-bare"        , 0.0000),
            ("border-round"       , 0.4615),
            ("border-staggered"   , 0.4615),
            ("border-thicc"       , 0.9231),
            ("border-greek"       , 0.9231),
            ("border-worn-saxon"  , 0.7692),
            ("border-saxon"       , 1.0000),
            ("ink-copper"         , 0.0000),
            ("ink-silver"         , 0.3333),
            ("ink-gold"           , 0.5833),
            ("ink-canopy"         , 0.8056),
            ("ink-rose"           , 0.8611),
            ("ink-spice"          , 0.9444),
            ("ink-midnight"       , 1.0000),
        ];

        // 3   saxon-saxon-copper
        // 2   saxon-saxon-silver
        // 2   saxon-saxon-gold
        // 2   worn-saxon-worn-saxon-canopy
        // 2   staggered-bordered-saxon-rose
        // 2   round-fate-spice
        // 2   staggered-fate-midnight
        // 6   thin-fate-copper
        // 5   thin-fate-silver
        // 6   bare-fate-copper
        // 5   bare-fate-silver
        // 4   round-fate-copper
        // 2   staggered-bordered-saxon-gold
        // 2   thicc-bordered-saxon-copper
        // 2   greek-bordered-saxon-gold
        // 3   worn-saxon-worn-saxon-copper
        // 2   thin-fate-gold
        // 1   thin-fate-canopy
        // 1   thin-fate-spice
        // 3   thin-bordered-saxon-copper
        // 2   thin-bordered-saxon-silver
        // 1   thin-bordered-saxon-gold
        // 1   thin-bordered-saxon-canopy
        // 1   bare-fate-gold
        // 2   bare-fate-canopy
        // 1   bare-fate-rose
        // 3   bare-bordered-saxon-copper
        // 2   bare-bordered-saxon-silver
        // 1   bare-bordered-saxon-gold
        // 1   bare-bordered-saxon-canopy
        // 2   round-fate-silver
        // 1   round-fate-gold
        // 2   round-fate-canopy
        // 1   round-fate-rose
        // 1   round-bordered-saxon-copper
        // 1   round-bordered-saxon-silver
        // 1   round-bordered-saxon-gold
        // 1   round-bordered-saxon-canopy
        // 3   staggered-fate-copper
        // 2   staggered-fate-silver
        // 1   staggered-fate-gold
        // 1   staggered-fate-canopy
        // 1   staggered-fate-rose
        // 1   staggered-bordered-saxon-copper
        // 1   staggered-bordered-saxon-silver
        // 2   thicc-fate-copper
        // 1   thicc-fate-silver
        // 1   thicc-fate-gold
        // 1   thicc-fate-rose
        // 1   thicc-bordered-saxon-silver
        // 1   thicc-bordered-saxon-gold
        // 1   thicc-bordered-saxon-rose
        // 2   greek-fate-copper
        // 1   greek-fate-silver
        // 1   greek-fate-gold
        // 1   greek-fate-spice
        // 1   greek-bordered-saxon-copper
        // 1   greek-bordered-saxon-silver
        // 1   greek-bordered-saxon-rose
        // 2   worn-saxon-worn-saxon-silver
        // 2   worn-saxon-worn-saxon-gold
        // 1   worn-saxon-worn-saxon-rose
        // 1   worn-saxon-worn-saxon-spice
        // 1   worn-saxon-worn-saxon-midnight
        // 1   saxon-saxon-spice
        // 1   saxon-saxon-midnight


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
            while (Nat32.toNat(i) < state.supply) {
                if (Option.isNull(ledger[Nat32.toNat(i)])) {
                    unminted.add(i);
                };
                i += 1;
            };
            return unminted.toArray();
        };

        // Get a random unminted token index.
        // Excludes non general sale tokens
        public func _getRandomMintIndex (
            exclude : ?[Ext.TokenIndex],
        ) : async ?Ext.TokenIndex {
            var i : Nat32 = 17;
            let unminted = Buffer.Buffer<Ext.TokenIndex>(0);
            label l while (Nat32.toNat(i) < state.supply) {
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
                switch (random.coin()) {
                    case (?r) {
                        if (r) {
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


        var ledger : [var ?Types.Token] = Array.init(state.supply, null);
        var legends : [Types.Legend] = [];

        // Provision ledger from stable state
        ledger := Array.thaw(state.ledger);

        // Provision legends from stable state
        legends := state.legends;

        public func toStable () : {
            ledger  : [?Types.Token];
            legends : [Types.Legend];
        } {
            {
                ledger = Array.freeze(ledger);
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
        ) : Result.Result<(Nat), Text> {
            assert(state.admins._isAdmin(caller));
            switch (_getNextMintIndex()) {
                case (?i) {
                    ledger[i] := ?{
                        createdAt = Time.now();
                        owner = Ext.User.toAccountIdentifier(to);
                        txId = "N/A";
                    };
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
            assert(state.admins._isAdmin(caller));
            if (conf.size() != state.supply) {
                return #err(
                    "Must include configuration for " #
                    Nat.toText(state.supply) #
                    " legends. Received " #
                    Nat.toText(conf.size())
                );
            };
            legends := conf;
            #ok();
        };

        // Reassign a lost NFT
        // @auth: admin
        public func reassign(
            caller  : Principal,
            token   : Ext.TokenIdentifier,
            to      : Ext.User,
            confirm : Text,
        ) : Result.Result<(), Text> {
            assert(state.admins._isAdmin(caller));
            if (confirm != "REASSIGN NFT") {
                return #err("Please confirm your intention to reassign an NFT by typing in \"REASSIGN NFT\"");
            };
            let index = switch (Ext.TokenIdentifier.decode(token)) {
                case (#err(_)) { return #err("Invalide token"); };
                case (#ok(_, tokenIndex)) Nat32.toNat(tokenIndex);
            };
            ledger[index] := ?{
                createdAt = switch (ledger[index]) {
                    case (?t) t.createdAt;
                    case _ Time.now();
                };
                owner = Ext.User.toAccountIdentifier(to);
                txId = "N/A";
            };
            #ok();
        };

        // Download a backup copy of the ledger.
        // @auth: admin
        public func backup (
            caller : Principal,
        ) : [?Types.Token] {
            assert(state.admins._isAdmin(caller));
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

    };

};