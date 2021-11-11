// 3rd Party Imports

import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

// Project Imports

import AssetTypes "../Assets/types";

// Module Imports

import Types "types";


module {

    public class Ledger (state : Types.State) {


        /////////////
        // Config //
        ///////////


        public let supply = {
            admins = 25;
            community = 25;
            general = 100;
            total = 150;
        };


        ////////////////////////
        // Utils / Internals //
        //////////////////////


        private func _getNextMintIndex () : ?Nat {
            var i : Nat = 0;
            for (v in ledger.vals()) {
                if (v == null) return ?i;
                i += 1;
            };
            return null;
        };

        private func _getMintsThisStage () : Nat {
            switch (mintingStage) {
                case (#admins) supply.admins - 1;
                case (#community) supply.community - 1;
                case (#general) supply.general - 1;
            };
        };

        public func _getLegend (i : Nat) : Types.Legend {
            legends[i];
        };


        ////////////
        // State //
        //////////


        var mintingStage : Types.MintingStage = #admins;
        var ledger : [var ?Principal] = Array.init(supply.total, null);
        var legends : [Types.Legend] = [];

        // Provision ledger from stable state
        ledger := Array.thaw(state.ledger);

        // Provision legends from stable state
        legends := state.legends;

        public func toStable () : {
            ledger  : [?Principal];
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
            to      : Principal,
        ) : Result.Result<(), Text> {
            assert(state.admins._isAdmin(caller));
            switch (_getNextMintIndex()) {
                case (?i) {
                    if (i <= _getMintsThisStage()) {
                        ledger[i] := ?to;
                        return #ok();
                    };
                    #err("No more supply this stage.");
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
            if (conf.size() != supply.total) {
                return #err(
                    "Must include configuration for " #
                    Nat.toText(supply.total) #
                    " legends. Received " #
                    Nat.toText(conf.size())
                );
            };
            legends := conf;
            #ok();
        };


        /////////////////
        // Public API //
        ///////////////


        public func read () : [?Principal] {
            Array.freeze(ledger);
        };


    };

};