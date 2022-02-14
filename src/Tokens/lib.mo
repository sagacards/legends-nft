import Array "mo:base/Array";
import Bool "mo:base/Bool";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Int8 "mo:base/Int8";
import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
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


        ////////////
        // State //
        //////////


        var ledger      : [var ?Types.Token]    = Array.init(Nat16.toNat(state.supply), null);
        var metadata    : [Types.Metadata]      = [];

        var isShuffled = state.isShuffled;

        // Dump all local state from this module for stableness purposes.
        public func toStable () : Types.LocalStableState {
            {
                metadata;
                isShuffled;
                tokens = Array.freeze(ledger);
            }
        };

        // Restore local state from a backup.
        public func _restore (
            backup  : Types.LocalStableState,
        ) : () {
            ledger      := Array.thaw(backup.tokens);
            metadata    := backup.metadata;
            isShuffled  := backup.isShuffled;
        };

        // Restore local state on init.
        _restore(state);


        ////////////////////////
        // Utils / Internals //
        //////////////////////


        public func _getNextMintIndex () : ?Nat32 {
            var i : Nat32 = 0;
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
            var i : Nat32 = 0;
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

        public func _getMetadata (i : Nat) : Types.Metadata {
            metadata[i];
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

        // NOTE: I lifted all of this randomness code from Moritz in the BTC Flower project
        // https://github.com/letmejustputthishere/btcflower-nft/blob/d0031f8fec88a9ee22b353a65e6d8d937458c437/btcflower-nft/lock_code.mo#L572

        private func _fromNat8ToInt(n : Nat8) : Int {
            Int8.toInt(Int8.fromNat8(n))
        };

        private func _fromIntToNat8(n: Int) : Nat8 {
            Int8.toNat8(Int8.fromIntWrap(n))
        };

        // Returns a pseudo random number between 0-99
        private func _prng(current: Nat8) : Nat8 {
            let next : Int =  _fromNat8ToInt(current) * 1103515245 + 12345;
            return _fromIntToNat8(next) % 100;
        };

        // A Fisher-Yates shuffle to make sure the minting process is fair.
        public func shuffleMetadata (
            caller : Principal,
        ) : async () {
            // The fool was sold before shuffling was a thing.
            assert(Principal.toText(state.cid) != "nges7-giaaa-aaaaj-qaiya-cai");
            assert(state._Admins._isAdmin(caller) and isShuffled == false);

            let seed: Blob = await Random.blob();

            var randomNumber : Nat8 = Random.byteFrom(seed);
            var currentIndex : Nat = metadata.size();            
            var shuffledMetadata = Array.thaw<Types.Metadata>(metadata);

            label l while (currentIndex != 1) {
                if (not Option.isNull(ledger[currentIndex - 1])) {
                    // Do not shuffle a minted token.
                    currentIndex -= 1;
                    continue l;
                };
                randomNumber := _prng(randomNumber);
                var randomIndex : Nat = Int.abs(Float.toInt(Float.floor(Float.fromInt(_fromNat8ToInt(randomNumber)* currentIndex/100))));
                assert(randomIndex < currentIndex);
                // TODO: Do not allow replacing a minted token index.
                // TODO: If there are no more unminted token indeces, break.
                currentIndex -= 1;
                let temporaryValue = shuffledMetadata[currentIndex];
                shuffledMetadata[currentIndex] := shuffledMetadata[randomIndex];
                shuffledMetadata[randomIndex] := temporaryValue;
            };

            metadata := Array.freeze(shuffledMetadata);
            isShuffled := true;
        };

        public func getTokens() : [(Ext.TokenIndex, Ext.Common.Metadata)] {
            let r = Buffer.Buffer<(Ext.TokenIndex, Ext.Common.Metadata)>(0);
            var i : Nat32 = 0;
            while (Nat32.toNat(i) < ledger.size()) {
                r.add((i, #nonfungible({ metadata = null })));
                i += 1;
            };
            r.toArray();
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
                    ledger[Nat32.toNat(i)] := ?{
                        createdAt = Time.now();
                        owner = Ext.User.toAccountIdentifier(to);
                        txId = "N/A";
                    };

                    // Insert transaction history event.
                    ignore await state._Cap.insert({
                        caller;
                        operation = "mint";
                        details = [
                            ("token", #Text(tokenId(state.cid, i))),
                            ("to", #Text(Ext.User.toAccountIdentifier(to))),
                            // TODO: Add price
                        ];
                    });
                    #ok(Nat32.toNat(i));
                };
                case _ #err("No more supply.");
            }
        };

        // @auth: admin
        public func configureMetadata (
            caller  : Principal,
            conf    : [Types.Metadata],
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
            metadata := conf;
            #ok();
        };

        // Download a backup copy of the ledger.
        // @auth: admin
        public func backup (
            caller : Principal,
        ) : Types.LocalStableState {
            assert(state._Admins._isAdmin(caller));
            toStable();
        };

        // Restore the ledger from a backup.
        // @auth: admin
        public func restore (
            caller  : Principal,
            backup  : Types.LocalStableState,
        ) : Result.Result<(), Text> {
            _restore(backup);
            #ok();
        };

        // @auth: admin
        public func readMeta () : [Types.Metadata] {
            metadata;
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


        public func nfts (index : ?Nat) : [Types.Metadata] {
            switch (index) {
                case (?i) [metadata[i]];
                case _ metadata;
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