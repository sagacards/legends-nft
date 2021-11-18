// 3rd Party Imports

import AccountIdentifier "mo:principal/AccountIdentifier";
import Array "mo:base/Array";
import Ext "mo:ext/Ext";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Prim "mo:prim";
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


        ////////////
        // State //
        //////////


        var mintingStage : Types.MintingStage = #admins;
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
        public func setMintingStage (
            caller  : Principal,
            stage   : Types.MintingStage,
        ) : async () {
            assert(state.admins._isAdmin(caller));
            mintingStage := stage;
        };

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