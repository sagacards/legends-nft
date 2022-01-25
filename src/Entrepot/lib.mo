import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Option "mo:base/Option";
import Prim "mo:prim";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Ext "mo:ext/Ext";

import NNS "../NNS";
import Types "types"


module {

    private let transactionTtl = 300_000_000_000;  // Time for a transaction to complete (5 mins.)

    public class Factory (state : Types.State) {


        ////////////
        // State //
        //////////


        // NFTs listed for sale.
        let listings = HashMap.HashMap<Ext.TokenIndex, Types.Listing>(
            state.listings.size(),
            Ext.TokenIndex.equal,
            Ext.TokenIndex.hash
        );

        // Unfinalized transactions.
        let pendingTransactions = HashMap.HashMap<Ext.TokenIndex, Types.Transaction>(
            state.pendingTransactions.size(),
            Ext.TokenIndex.equal,
            Ext.TokenIndex.hash
        );

        var nextTxId = 0;

        // Finalized transactions.
        let transactions = HashMap.HashMap<Nat, Types.Transaction>(
            state.transactions.size(),
            Nat.equal,
            Nat32.fromNat
        );

        // Used payment addresses.
        // NOTE: Payment addresses are generated at transaction time by combining random subaccount bytes (determined in secret by the buyer,) with the seller's address. The transaction protocol relies on a unique address for each transaction, so these payment addresses can never be used again.
        private let _usedPaymentAddresses : Buffer.Buffer<(
            Ext.AccountIdentifier, Principal, Ext.SubAccount
        )> = Buffer.Buffer(0);

        // Marketplace stats
        var totalVolume         : Nat64 = 0;
        var lowestPriceSale     : Nat64 = 0;
        var highestPriceSale    : Nat64 = 0;
        var currentFloorPrice   : Nat64 = 0;

        // Pre upgrade

        public func toStable () : {
            listings                : [(Ext.TokenIndex, Types.Listing)];
            transactions            : [(Nat, Types.Transaction)];
            pendingTransactions     : [(Ext.TokenIndex, Types.Transaction)];
            _usedPaymentAddresses   : [(Ext.AccountIdentifier, Principal, Ext.SubAccount)];
        } {
            {
                listings = Iter.toArray(listings.entries());
                transactions = Iter.toArray(transactions.entries());
                pendingTransactions = Iter.toArray(pendingTransactions.entries());
                _usedPaymentAddresses = _usedPaymentAddresses.toArray();
            }
        };

        // Post upgrade

        private func _restore (
            backup : Types.State,
        ) : () {
            for ((k, v) in backup.listings.vals()) listings.put(k, v);
            for ((k, v) in backup.transactions.vals()) transactions.put(k, v);
            for ((k, v) in backup.pendingTransactions.vals()) {
                if (Time.now() < (v.initiated + transactionTtl)) {
                    pendingTransactions.put(k, v);
                };
            };
            for (x in backup._usedPaymentAddresses.vals()) _usedPaymentAddresses.add(x);
        };

        _restore(state);

        public func restore (
            caller : Principal,
            backup : Types.State,
        ) : () {
            assert state._Admins._isAdmin(caller);
            _restore(backup);
        };


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


        // Check to see if a listing is locked.
        func _isLocked (
            index : Ext.TokenIndex,
        ) : Bool {
            switch (listings.get(index)) {
                case (?listing) {
                    switch (listing.locked) {
                        case (?locked) {
                            if (Time.now() <= locked) {
                                true;
                            } else {
                                false;
                            }
                        };
                        case _ false;
                    };
                };
                case _ false;
            };
        };

        // Ensure that a token listing is not settleable. Will settle a tranaction if possible to do so. This can be called before marketplace operations because it's possible that a buyer submitted payment, but did not correctly settle the transaction. In such a case, some ICP could end up being misallocated or lost.
        // NOTE: This is all ripped from Toniq labs. My understanding of these usecases is not great. Be careful about refactoring.
        func _canSettle (
            token : Ext.TokenIdentifier
        ) : async Result.Result<(), Ext.CommonError> {

            // Decode token index.
            let index = switch (Ext.TokenIdentifier.decode(token)) {
                case (#err(_)) { return #err(#InvalidToken(token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };

            switch (pendingTransactions.get(index)) {
                case (?tx) {
                    // Attempt to settle the pending transaction.
                    switch (await settle(token)) {
                        case (#ok) {
                            // The old transaction was able to be settled.
                            return #err(#Other("Listing has been sold."));
                        };
                        case(#err _) {
                            if (Option.isNull(listings.get(index))) {
                                // The transaction was settled from under our feet.
                                // NOTE: This is such a weird deep use case 😵‍💫
                                return #err(#Other("Listing as sold"));
                            };
                        };
                    };
                };
                case _ ();
            };
            #ok();
        };

        // Ensure a payment address is unique.
        func _isUniquePaymentAddress (
            address : Ext.AccountIdentifier,
        ) : Bool {
            switch (
                Array.find(
                    _usedPaymentAddresses.toArray(),
                    func (a : (Ext.AccountIdentifier, Principal, Ext.SubAccount)) : Bool {
                        a.0 == address
                    }
                )
             ) {
                case (?x) false;
                case _ true;
            };
        };

        // Get index from EXT token identifier.
        func _unpackTokenIdentifier (
            token : Ext.TokenIdentifier,
        ) : Result.Result<Ext.TokenIndex, Ext.CommonError> {
            switch (Ext.TokenIdentifier.decode(token)) {
                case (#ok(principal, tokenIndex)) {
                    // Validate token identifier's canister.
                    if (principal != state.cid) {
                        #err(#InvalidToken(token));
                    } else {
                        #ok(tokenIndex);
                    };
                };
                case (#err(_)) { return #err(#InvalidToken(token)); };
            };
        };


        ////////////////
        // Admin API //
        //////////////


        public func readPending (
            caller  : Principal,
        ) : [(Ext.TokenIndex, Types.Transaction)] {
            Iter.toArray(pendingTransactions.entries())
        };


        /////////////////
        // Public API //
        ///////////////


        // List NFTs up for sale
        public func getListings () : Types.ListingsResponse {
            let r = Buffer.Buffer<(Ext.TokenIndex, Types.ExtListing, Types.Metadata)>(0);
            for ((k, v) in listings.entries()) {
                r.add(
                    (
                        k,
                        {
                            locked  = v.locked;
                            seller  = v.seller;
                            price   = v.price;
                        },
                        #nonfungible({ metadata = null })
                    )
                )
            };
            return r.toArray();
        };

        // Put an NFT up for sale
        public func list (
            caller  : Principal,
            request : Types.ListRequest,
        ) : async Types.ListResponse {
            // Decode token index.
            let index = switch (Ext.TokenIdentifier.decode(request.token)) {
                case (#err(_)) { return #err(#InvalidToken(request.token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };
            
            // Verify token owner.
            if (not state._Tokens._isOwner(_accountId(caller, request.from_subaccount), index)) {
                return #err(#Other("Unauthorized"));
            };

            // Ensure token is not already locked.
            if (_isLocked(index)) {
                return #err(#Other("Token is locked."));
            };

            // Ensure there isn't a pending transaction which can be settled.
            switch (await _canSettle(request.token)) {
                case (#err(e)) return #err(e);
                case _ ();
            };

            // NOTE: The interface to delete a listing is not explicit enough for my taste.
            switch (request.price) {
                // Create the listing.
                case (?price) {
                    listings.put(index, {
                        locked      = null;
                        seller      = caller;
                        subaccount  = request.from_subaccount;
                        price       = price;
                    });
                };
                // If price is null, delete the listing.
                case _ {
                    listings.delete(index);
                };
            };
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
                Nat16.toNat(state.supply),
                transactions.size(),
            );
        };

        // Execute a lock on an NFT so that we can safely conduct a transaction.
        public func lock (
            caller  : Principal,
            token   : Ext.TokenIdentifier,
            price   : Nat64,
            buyer   : Ext.AccountIdentifier,
            bytes   : [Nat8],
        ) : async Types.LockResponse {

            // Validate subaccount bytes.
            // NOTE: This subaccount is a secret created by the buyer. Therefore, it should never be exposed to the seller until the seller's side is fulfilled. These bytes are hashed with the seller's address to create an escrow address, which is a critical component of this protocol.
            // TODO: Is it possible that a subaccount is being created on the seller's principal, without the seller being able to control that money?
            if (bytes.size() != 32) {
                return #err(#Other("Invalid subaccount."));
            };

            // Disallow the zero subaccount.
            // NOTE: A vulnerability was discovered where using the zero subaccount here would allow a bad actor to buy an NFT using the seller's own money.
            var i : Nat = 0;
            var failed : Bool = true;
            while(i < 29) {
                if (failed) {
                    if (bytes[i] > 0) { 
                    failed := false;
                    };
                };
                i += 1;
            };

            // Decode token index from token identifier.
            let index : Ext.TokenIndex = switch (_unpackTokenIdentifier(token)) {
                case (#ok(i)) i;
                case (#err(e)) return #err(e);
            };

            // Ensure token is not already locked.
            if (_isLocked(index)) {
                return #err(#Other("Already locked."));
            };

            // Retrieve the token's listing.
            switch (listings.get(index)) {
                case (null) #err(#Other("No such listing."));

                case (?listing) {

                    // Double check listing price
                    if (price != listing.price) {
                        return #err(#Other("Incorrect listing price."));
                    };

                    // Ensure the payment address is unique.
                    // TODO: Ensure the AccountIdentifier hashing is done correctly.
                    let paymentAddress : Ext.AccountIdentifier = AccountIdentifier.toText(
                        AccountIdentifier.fromPrincipal(
                            listing.seller,
                            ?bytes,
                        )
                    );
                    if (not _isUniquePaymentAddress(paymentAddress)) {
                        return #err(#Other("Payment address is not unique"));
                    };

                    // Lock the listing
                    listings.put(index, {
                        price       = listing.price;
                        seller      = listing.seller;
                        subaccount  = listing.subaccount;
                        locked      = ?(Time.now() + transactionTtl);
                    });

                    // TODO: In the event that a balance of ICP is "stuck," what can we do? Doesn't the seller have control of it?

                    // TODO: Can I replace the mechanism with something that uses ICP in a canister, while maintaining the same API?

                    // Ensure there isn't a pending transaction which can be settled.
                    switch (await _canSettle(token)) {
                        case (#err(e)) return #err(e);
                        case _ ();
                    };

                    // Retire the payment address.
                    _usedPaymentAddresses.add((paymentAddress, listing.seller, bytes));

                    // Create a pending transaction
                    // NOTE: Keys in this map are TOKEN INDECES. Upon settlement, a transaction is moved to the "finalized transactions" map, which used a generic transaction ID as a key. Effectively, the key type changes during a settlement. This is at best an unclear thing to do, so perhaps worthy of a refactor.
                    pendingTransactions.put(index, {
                        id          = nextTxId;
                        token       = token;
                        memo        = null;
                        seller      = listing.seller;
                        from        = _accountId(listing.seller, listing.subaccount);
                        to          = buyer;
                        price       = listing.price;
                        initiated   = Time.now();
                        closed      = null;
                        bytes;
                    });
                    nextTxId += 1;  // Don't forget this 😬

                    #ok(paymentAddress);
                    
                };
            };
        };

        // As the final step, after transfering ICP, we can settle the transaction.
        public func settle (
            token   : Ext.TokenIdentifier,
        ) : async Result.Result<(), Ext.CommonError> {
            // Decode token index from token identifier.
            let index : Ext.TokenIndex = switch (_unpackTokenIdentifier(token)) {
                case (#ok(i)) i;
                case (#err(e)) return #err(e);
            };

            // Retrieve the pending transaction.
            let transaction = switch (pendingTransactions.get(index)) {
                case (?t) t;
                case _ return #err(#Other("No such pending transaction."));
            };

            // Verify token owner.
            if (not state._Tokens._isOwner(transaction.from, index)) {
                let v = switch (state._Tokens._getOwner(Nat32.toNat(index))) {
                    case (?t) t.owner;
                    case _ "undefined";
                };
                return #err(#Other(transaction.from # " is not owner (" # v # ")."));
            };

            // Check the transaction account on the nns ledger canister.
            let balance = await state._Nns.balance(
                NNS.accountIdentifier(
                    transaction.seller,
                    Blob.fromArray(transaction.bytes),
                )
            );

            if (balance.e8s < transaction.price) {
                return #err(#Other("Insufficient funds sent."));
            };

            // Update the transaction.
            // NOTE: We use the id of the pending transaction as the key. The pending transaction map uses TOKEN INDECES for keys, but this is an intentional change.
            transactions.put(transaction.id, {
                id          = transaction.id;
                memo        = transaction.memo;
                from        = transaction.from;
                to          = transaction.to;
                price       = transaction.price;
                initiated   = transaction.initiated;
                closed      = ?Time.now();
                bytes       = transaction.bytes;
                seller      = transaction.seller;
                token       = transaction.token;
            });
            pendingTransactions.delete(index);

            // Transfer the NFT.
            state._Tokens.transfer(
                index,
                transaction.from,
                transaction.to
            );

            // Remove the listing.
            listings.delete(index);

            // Insert transaction history event.
            ignore await state._Cap.insert({
                caller = state.cid;
                operation = "sale";
                details = [
                    ("to", #Text(transaction.to)),
                    ("from", #Text(transaction.from)),
                    ("token", #Text(state._Tokens.tokenId(state.cid, index))),
                    ("memo", #Slice(
                        switch (transaction.memo) {
                            case (?x) Blob.toArray(x);
                            case _ [];
                        }
                    )),
                    ("balance", #U64(1)),
                    ("price_decimals", #U64(8)),
                    ("price_currency", #Text("ICP")),
                    ("price", #U64(transaction.price)),
                ];
            });

            #ok();
        };

        public func payments (
            caller  : Principal,
        ) : ?[Ext.SubAccount] {
            ?Array.mapFilter<(Nat, Types.Transaction), Ext.SubAccount>(Iter.toArray(transactions.entries()), func ((index, transaction)) {
                if (transaction.seller == caller) {
                    ?transaction.bytes;
                } else {
                    null;
                };
            });
        };

        // Used by stoic wallet
        public func tokens_ext(
            caller  : Principal,
            accountId : Ext.AccountIdentifier,
        ) : Result.Result<[(Ext.TokenIndex, ?Types.Listing, ?[Nat8])], Ext.CommonError> {
            let tokens = Buffer.Buffer<(Ext.TokenIndex, ?Types.Listing, ?[Nat8])>(0);
            var i : Nat32 = 0;
            for (token in Iter.fromArray(state._Tokens.read(null))) {
                switch (token) {
                    case (?t) {
                        if (Ext.AccountIdentifier.equal(accountId, t.owner)) {
                            tokens.add((
                                i,
                                listings.get(i),
                                null,
                            ));
                        };
                    };
                    case _ ();
                };
                i += 1;
            };
            #ok(tokens.toArray());
        };


        // Return completed transactions.
        public func readTransactions () : [Types.EntrepotTransaction] {
            Array.map<(Nat, Types.Transaction), Types.EntrepotTransaction>(Iter.toArray(transactions.entries()), func ((k, v)) {
                {
                    buyer   = v.to;
                    price   = v.price;
                    seller  = v.seller;
                    time    = switch(v.closed) {
                        case (?t) t;
                        case _ v.initiated;
                    };
                    token   = v.token;
                }
            });
        };

    };

};