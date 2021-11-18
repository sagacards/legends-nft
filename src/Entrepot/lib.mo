import AccountIdentifier "mo:principal/AccountIdentifier";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Ext "mo:ext/Ext";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Prim "mo:prim";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import Types "types"

module {


    // Config

    public let transactionTtl = 300_000_000_000;  // Time for a transaction to complete (5 mins.)


    // Entrepot state and APIs

    public class Factory (state : Types.State) {


        ///////////////////////
        // Internal / Utils //
        /////////////////////


        // Turn a principal and a subaccount into an uppercase textual account id.
        func _accountId(
            principal   : Principal,
            subaccount  : ?Ext.SubAccount,
        ) : Ext.AccountIdentifier {
            let aid = AccountIdentifier.fromPrincipal(principal, subaccount);
            Text.map(AccountIdentifier.toText(aid), Prim.charToUpper);
        };


        ////////////
        // State //
        //////////


        var nextTxId = 0;
        let listings = HashMap.HashMap<Ext.TokenIndex, Types.Listing>(
            state.listings.size(),
            Ext.TokenIndex.equal,
            Ext.TokenIndex.hash
        );
        // TODO: this could be a reasonably sized FIFO; can die after ttl
        let pendingTransactions = HashMap.HashMap<Ext.TokenIndex, Types.Transaction>(
            state.pendingTransactions.size(),
            Ext.TokenIndex.equal,
            Ext.TokenIndex.hash
        );
        let transactions = HashMap.HashMap<Nat, Types.Transaction>(
            state.transactions.size(),
            Nat.equal,
            Nat32.fromNat
        );

        var totalVolume         : Nat64 = 0;
        var lowestPriceSale     : Nat64 = 0;
        var highestPriceSale    : Nat64 = 0;
        var currentFloorPrice   : Nat64 = 0;

        // Pre upgrade

        public func toStable () : {
            listings            : [(Ext.TokenIndex, Types.Listing)];
            transactions        : [(Nat, Types.Transaction)];
            pendingTransactions : [(Ext.TokenIndex, Types.Transaction)];
        } {
            {
                listings = Iter.toArray(listings.entries());
                transactions = Iter.toArray(transactions.entries());
                pendingTransactions = Iter.toArray(pendingTransactions.entries());
            }
        };

        // Post upgrade

        for ((k, v) in Iter.fromArray(state.listings)) listings.put(k, v);
        for ((k, v) in Iter.fromArray(state.transactions)) transactions.put(k, v);
        for ((k, v) in Iter.fromArray(state.pendingTransactions)) {
            if (Time.now() < (v.initiated + transactionTtl)) {
                pendingTransactions.put(k, v);
            };
        };


        /////////////////
        // Public API //
        ///////////////


        // Get NFTs up for sale
        public func getListings () : Types.ListingsResponse {
            let r = Buffer.Buffer<(Ext.TokenIndex, Types.Listing, Types.Metadata)>(0);
            for ((k, v) in listings.entries()) {
                r.add((k, v, #nonfungible({ metadata = ?Text.encodeUtf8("The Fool") })))
            };
            return r.toArray();
        };

        // Put an NFT up for sale
        public func list (
            caller  : Principal,
            request : Types.ListRequest,
        ) : Types.ListResponse {
            let index = switch (Ext.TokenIdentifier.decode(request.token)) {
                case (#err(_)) { return #err(#InvalidToken(request.token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            if (not state.ledger._isOwner(_accountId(caller, request.from_subaccount), index)) {
                return #err(#Other("Unauthorized"));
            };
            listings.put(index, {
                locked      = null;
                seller      = caller;
                subaccount  = request.from_subaccount;
                price       = switch (request.price) {
                    case (?p) p;
                    case _ 400_000_000;  // Weird to me that price is optional. 4ICP floor is the goal, so...
                };
            });
            #ok();
        };

        // Get market details for an NFT (i.e. is it for sale, how much)
        public func details (token : Ext.TokenIdentifier) : Types.DetailsResponse {
            let index = switch (Ext.TokenIdentifier.decode(token)) {
                case (#err(_)) { return #err(#InvalidToken(token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (listings.get(index)) {
                case (?listing) #ok((_accountId(listing.seller, listing.subaccount), ?listing));
                case _ #err(#Other("No such listing."));
            };
        };

        // Get market stats for this collection
        public func stats () : Types.StatsResponse {
            (
                totalVolume,
                highestPriceSale,
                lowestPriceSale,
                currentFloorPrice,
                listings.size(),
                state.supply,
                transactions.size(),
            );
        };

        // Execute a lock on an NFT so that we can safely conduct a transaction
        public func lock (
            caller  : Principal,
            token   : Ext.TokenIdentifier,
            price   : Nat64,
            buyer   : Ext.AccountIdentifier,
            bytes   : [Nat8],                 // Random bytes
        ) : Types.LockResponse {
            // let callerAccount = Text.map(AccountIdentifier.toText(AccountIdentifier.fromPrincipal(caller, null)), Prim.charToLower);
            // if (Text.map(buyer, Prim.charToLower) != callerAccount) {
            //     return #err(#Other("Caller must be purchaser (\"" # callerAccount #"\" vs \"" # Text.map(buyer, Prim.charToLower) # "\")."));
            // };
            let index = switch (Ext.TokenIdentifier.decode(token)) {
                case (#err(_)) { return #err(#InvalidToken(token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            switch (listings.get(index)) {
                case (?listing) {
                    switch (listing.locked) {
                        case (?locked) {
                            if (Time.now() < locked) {
                                return #err(#Other("Already locked."));
                            };
                        };
                        case _ ();
                    };
                    // Create a pending transaction
                    pendingTransactions.put(index, {
                        id          = nextTxId;
                        memo        = ?Blob.fromArray(bytes);
                        from        = _accountId(listing.seller, listing.subaccount);
                        to          = buyer;
                        price       = listing.price;
                        initiated   = Time.now();
                        closed      = null;
                    });
                    nextTxId += 1;
                    // Lock the listing
                    listings.put(index, {
                        price       = listing.price;
                        seller      = listing.seller;
                        subaccount  = listing.subaccount;
                        locked      = ?(Time.now() + transactionTtl);
                    });
                    #ok(_accountId(listing.seller, listing.subaccount));
                };
                case _ #err(#Other("No such listing."));
            };
        };

        // As the final step, after transfering ICP, we can settle the transaction.
        public func settle (
            tokenId : Ext.TokenIdentifier,
        ) : Result.Result<(), Ext.CommonError> {
            let index = switch (Ext.TokenIdentifier.decode(tokenId)) {
                case (#err(_)) return #err(#InvalidToken(tokenId));
                case (#ok(_, tokenIndex)) tokenIndex;
            };
            // Validate the pending transaction.
            let transaction = switch (pendingTransactions.get(index)) {
                case (?t) t;
                case _ return #err(#Other("No such pending transaction."));
            };
            // NOTE: !!!! Not sure how I'm supposed to validate the transaction here.
            // Update the transaction.
            transactions.put(transaction.id, {
                id          = transaction.id;
                memo        = transaction.memo;
                from        = transaction.from;
                to          = transaction.to;
                price       = transaction.price;
                initiated   = transaction.initiated;
                closed      = ?Time.now();
            });
            pendingTransactions.delete(index);
            // Transfer the NFT.
            if (not state.ledger._isOwner(transaction.from, index)) {
                // NOTE: !!!! An error here will cause a transaction not to complete AFTER funds are transferred. Bad!!!!
                let v = switch (state.ledger._getOwner(Nat32.toNat(index))) {
                    case (?t) t.owner;
                    case _ "undefined";
                };
                return #err(#Other(transaction.from # " is not " # v));
            };
            state.ledger.transfer(
                index,
                transaction.from,
                transaction.to
            );
            // Remove the listing.
            listings.delete(index);
            #ok();
        };


        ////////////////
        // Admin API //
        //////////////


        public func purgeListings (
            caller  : Principal,
            confirm : Text,
        ) : Result.Result<(), Text> {
            assert(state.admins._isAdmin(caller));
            if (confirm != "PURGE ENTREPOT LISTINGS") {
                return #err("Please confirm your intention to purge all entrepot listings by typing in \"PURGE ENTREPOT LISTINGS\"");
            };
            for ((k, v) in listings.entries()) listings.delete(k);
            #ok();
        };

    };

};