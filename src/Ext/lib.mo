import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Ext "mo:ext/Ext";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import LedgerTypes "../Ledger/types";

import Types "types";

module {

    public class make (state : Types.State) {


        ////////////////
        // @ext:core //
        //////////////


        public func balance(
            canister : Principal,
            request : Ext.Core.BalanceRequest,
        ) : Ext.Core.BalanceResponse {
            let index = switch (Ext.TokenIdentifier.decode(request.token)) {
                case (#err(_)) { return #err(#InvalidToken(request.token)); };
                case (#ok(canisterId, tokenIndex)) {
                    if (canisterId != canister) return #err(#InvalidToken(request.token));
                    tokenIndex;
                };
            };

            let userId = Ext.User.toAccountIdentifier(request.user);
            switch (state.ledger._getOwner(Nat32.toNat(index))) {
                case (null) { #err(#InvalidToken(request.token)); };
                case (? token) {
                    if (Ext.AccountIdentifier.equal(userId, token.owner)) {
                        #ok(1);
                    } else {
                        #ok(0);
                    };
                };
            };
        };

        public func extensions() : [Ext.Extension] {
            ["@ext/common", "@ext/nonfungible"];
        };

        public func transfer(
            caller : Principal,
            request : Ext.Core.TransferRequest,
        ) : Ext.Core.TransferResponse {
            #err(#Other("disabled"));
        };

        //////////////////
        // @ext:common //
        ////////////////

        // TODO
        public func metadata(
            tokenId : Ext.TokenIdentifier,
        ) : Ext.Common.MetadataResponse {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) { return #err(#InvalidToken(tokenId)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (state.ledger._getOwner(Nat32.toNat(index))) {
                case (null) { #err(#InvalidToken(tokenId)); };
                case (?token) { #ok(#nonfungible({metadata = ?Text.encodeUtf8("Cake Slice")})); };
            };
        };

        public func supply(
            tokenId : Ext.TokenIdentifier,
        ) : Ext.Common.SupplyResponse {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) { return #err(#InvalidToken(tokenId)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (state.ledger._getOwner(Nat32.toNat(index))) {
                case (null) { #ok(0); };
                case (? _)  { #ok(1); };
            };
        };

        ///////////////////////
        // @ext:nonfungible //
        /////////////////////

        public func bearer(
            tokenId : Ext.TokenIdentifier,
        ) : Ext.NonFungible.BearerResponse {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) { return #err(#InvalidToken(tokenId)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (state.ledger._getOwner(Nat32.toNat(index))) {
                case (null)    { #err(#InvalidToken(tokenId)); };
                case (? token) { #ok(token.owner); };
            };
        };

        // public type CustomMintRequest = {
        //     to        : Ext.User;
        //     tokenType : TokenType;
        //     txId      : Text;
        // };

        // public shared({caller}) func mintNFTCustom(
        //     request : CustomMintRequest,
        // ) : Ext.NonFungible.MintResponse {
        //     if (caller != owner) return #err(#Other("not authorized"));
        //     switch (txLedger.get(request.txId)) {
        //         case (? tokenId) { return #err(#Other("already minted: " # Nat32.toText(tokenId))); };
        //         case (_) {};
        //     };
        //     let receiverId = Ext.User.toAccountIdentifier(request.to);
        //     let index = nextTokenId;
        //     tokenLedger.put(index, {
        //         createdAt = Time.now();
        //         owner     = receiverId;
        //         tokenType = request.tokenType;
        //         txId      = request.txId;
        //     });
        //     txLedger.put(request.txId, index);
        //     nextTokenId += 1;
        //     #ok(index);
        // };

        // public shared({ caller }) func mintNFT (
        //     request : Ext.NonFungible.MintRequest,
        // ) : Ext.NonFungible.MintResponse {
        //     state.ledger.mint(caller, request.to);
        // };

        /////////////////////
        // @ext:allowance //
        ///////////////////

        public func allowance(
            caller  : Principal,
            request : Ext.Allowance.Request,
        ) : Ext.Allowance.Response {
            #err(#Other("disabled"));
        };

        public func approve(
            caller  : Principal,
            request : Ext.Allowance.ApproveRequest,
        ) : () {};

        /////////////////////////////
        // @ext:stoic integration //
        ///////////////////////////

        public func tokens(
            caller  : Principal,
            accountId : Ext.AccountIdentifier
        ) : Result.Result<[Ext.TokenIndex], Ext.CommonError> {
            var tokens : [Ext.TokenIndex] = [];
            var i : Nat32 = 0;
            for (token in Iter.fromArray(state.ledger.read(null))) {
                switch (token) {
                    case (?t) {
                        if (Ext.AccountIdentifier.equal(accountId, t.owner)) {
                            tokens := Array.append(tokens, [i]);
                        };
                    };
                    case _ ();
                };
                i += 1;
            };
            #ok(tokens);
        };
        
        public func tokens_ext(
            caller  : Principal,
            accountId : Ext.AccountIdentifier,
        ) : Result.Result<[Types.TokenExt], Ext.CommonError> {
            var tokens : [Types.TokenExt] = [];
            var i : Nat32 = 0;
            for (token in Iter.fromArray(state.ledger.read(null))) {
                switch (token) {
                    case (?t) {
                        if (Ext.AccountIdentifier.equal(accountId, t.owner)) {
                            tokens := Array.append(tokens, [(
                                i,
                                null,
                                null,
                            )]);
                        };
                    };
                    case _ ();
                };
                i += 1;
            };
            #ok(tokens);
        };

        public func details(
            caller  : Principal,
            tokenId : Ext.TokenIdentifier,
        ) : Result.Result<(Ext.AccountIdentifier, ?Types.Listing), Ext.CommonError> {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) { return #err(#Other("Something went wrong.")); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (state.ledger._getOwner(Nat32.toNat(index))) {
                case (? token) { #ok((token.owner, null)); };
                case (null)    { #err(#Other("Something went wrong.")); };
            };
        };

        ///////////////////////
        // Non-standard EXT //
        /////////////////////

        public func tokenId(
            canister : Principal,
            index : Ext.TokenIndex,
        ) : Ext.TokenIdentifier {
            Ext.TokenIdentifier.encode(canister, index);
        };
    };
};