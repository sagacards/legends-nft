import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import AccountBlob "mo:principal/blob/AccountIdentifier";
import Ext "mo:ext/Ext";

import TokenTypes "../Tokens/types";
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
            switch (state._Tokens._getOwner(Nat32.toNat(index))) {
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

        // @notice Transfers the ownership of an NFT from one address to another address
        // @dev Throws unless `msg.caller` is the current owner. Throws if `request.from` is not the current owner. Throws if a valid token index cannot be decoded from `request.token`. Throws if `request.token` is not a valid NFT. NOTE: Should have lots of notes about notify async, but I don't implement it. Throws if the NFT is listed on markets (TODO: could verify lock/pending tx/settle and delist.)
        // @data request.from (EXT.User) The current owner of the NFT
        // @data request.to (EXT.User) The new owner
        // @data request.token (EXT.TokenIdentifier) The nft to transfer 
        // @data request.amount (Nat) Number of tokens to transfer (must be 1)
        // @data request.memo (Blob) Additional data with no specified format
        // @data request.notify (Boolean) If true will attempt to notify recipient
        // @data request.subaccount (?[Nat8]) Subaccount of the caller
        public func transfer(
            caller : Principal,
            request : Ext.Core.TransferRequest,
        ) : async Ext.Core.TransferResponse {
            let index = switch (Ext.TokenIdentifier.decode(request.token)) {
                case (#err(_)) { return #err(#InvalidToken(request.token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            let token = switch (state._Tokens._getOwner(Nat32.toNat(index))) {
                case (?t) t;
                case _ return #err(#Other("Token owner doesn't exist."));
            };
            let callerAccount = Text.map(AccountBlob.toText(AccountBlob.fromPrincipal(caller, request.subaccount)), Prim.charToUpper);
            let from = Text.map(Ext.User.toAccountIdentifier(request.from), Prim.charToUpper);
            let to = Text.map(Ext.User.toAccountIdentifier(request.to), Prim.charToUpper);
            let owner = Text.map(token.owner, Prim.charToUpper);
            if (owner != from) return #err(#Unauthorized("Owner \"" # owner # "\" is not caller \"" # from # "\""));
            if (from != callerAccount) return #err(#Unauthorized("Only the owner can do that."));
            if (not Option.isNull(state._Entrepot._getListing(index))) return #err(#Other("This token is currently listed for sale!"));
            state._Tokens.transfer(index, callerAccount, to);

            // Insert transaction history event.
            ignore await state._Cap.insert({
                caller = caller;
                operation = "transfer";
                details = [
                    ("token", #Text(tokenId(state.cid, index))),
                    ("to", #Text(to)),
                    ("from", #Text(from)),
                    ("memo", #Slice(Blob.toArray(request.memo))),
                    ("balance", #U64(1)),
                ];
            });
            #ok(Nat32.toNat(index));
        };

        //////////////////
        // @ext:common //
        ////////////////

        public func metadata(
            caller  : Principal,
            tokenId : Ext.TokenIdentifier,
        ) : Ext.Common.MetadataResponse {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) { return #err(#InvalidToken(tokenId)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (state._Tokens._getOwner(Nat32.toNat(index))) {
                case (null) { #err(#InvalidToken(tokenId)); };
                case (?token) { #ok(#nonfungible({metadata = ?Text.encodeUtf8("The Fool")})); };
            };
        };

        public func supply(
            tokenId : Ext.TokenIdentifier,
        ) : Ext.Common.SupplyResponse {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) { return #err(#InvalidToken(tokenId)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (state._Tokens._getOwner(Nat32.toNat(index))) {
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
            switch (state._Tokens._getOwner(Nat32.toNat(index))) {
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
        //     state._Tokens.mint(caller, request.to);
        // };

        public func getRegistry() : [(Ext.TokenIndex, Ext.AccountIdentifier)] {
            var i : Nat32 = 0;
            Array.mapFilter<?TokenTypes.Token, (Ext.TokenIndex, Ext.AccountIdentifier)>(
                state._Tokens.read(null),
                func (a) {
                    switch (a) {
                        case (?a) {
                            let r = ?(i, a.owner);
                            i += 1;
                            r;
                        };
                        case _ {
                            i += 1;
                            null;
                        };
                    }
                }
            );
        };

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
            for (token in Iter.fromArray(state._Tokens.read(null))) {
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