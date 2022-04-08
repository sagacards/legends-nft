import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Prim "mo:prim";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Ext "mo:ext/Ext";
import Hex "mo:encoding/Hex";

import NNS "../NNS";
import NNSTypes "../NNS/types";
import Types "types"


module {

    // Time for a transaction to complete (2 mins.)
    private let transactionTtl = 120_000_000_000;

    // Fees to be deducted from all marketplace sales
    private let fees : [(Ext.AccountIdentifier, Nat64)] = [
        ("ea6e340b18837860b1d9f353af06d459af55c74d97ef3ac024c2a42778e3e030", 2), // 2% Royalty fee
        ("c7e461041c0c5800a56b64bb7cefc247abc0bbbb99bd46ff71c64e92d9f5c2f9", 1), // 1% Entrepot marketplace fee
    ];

    let nns : NNSTypes.NNS = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");

    public class Factory (state : Types.State) {


        ////////////
        // State //
        //////////


        // NFTs listed for sale.
        private var listings = HashMap.HashMap<Ext.TokenIndex, Types.Listing>(
            state.listings.size(),
            Ext.TokenIndex.equal,
            Ext.TokenIndex.hash
        );

        // Unfinalized transactions.
        private var pendingTransactions = HashMap.HashMap<Ext.TokenIndex, Types.Transaction>(
            state.pendingTransactions.size(),
            Ext.TokenIndex.equal,
            Ext.TokenIndex.hash
        );

        // Incrementing transaction id.
        private var nextTxId = 0;

        // Finalized transactions.
        private var transactions = HashMap.HashMap<Nat, Types.Transaction>(
            state.transactions.size(),
            Nat.equal,
            Nat32.fromNat
        );

        // Used payment addresses.
        // DEPRECATED
        // NOTE: Payment addresses are generated at transaction time by combining random subaccount bytes (determined in secret by the buyer,) with the seller's address. The transaction protocol relies on a unique address for each transaction, so these payment addresses can never be used again.
        private var _usedPaymentAddresses : Buffer.Buffer<(
            Ext.AccountIdentifier, Principal, Ext.SubAccount
        )> = Buffer.Buffer(0);

        // Incrementing subaccount for handling marketplace payments.
        private var nextSubAccount : Nat = state.nextSubAccount;

        // Marketplace stats
        var totalVolume         : Nat64 = state.totalVolume;
        var lowestPriceSale     : Nat64 = state.lowestPriceSale;
        var highestPriceSale    : Nat64 = state.highestPriceSale;

        // Pending ICP disbursements from this canister.
        var pendingDisbursements : List.List<Types.Disbursement> = null;

        // Pre upgrade

        public func toStable () : {
            listings                : [(Ext.TokenIndex, Types.Listing)];
            transactions            : [(Nat, Types.Transaction)];
            pendingTransactions     : [(Ext.TokenIndex, Types.Transaction)];
            _usedPaymentAddresses   : [(Ext.AccountIdentifier, Principal, Ext.SubAccount)];
            totalVolume             : Nat64;
            lowestPriceSale         : Nat64;
            highestPriceSale        : Nat64;
            nextSubAccount          : Nat;
            pendingDisbursements    : [Types.Disbursement];
        } {
            {
                listings = Iter.toArray(listings.entries());
                transactions = Iter.toArray(transactions.entries());
                pendingTransactions = Iter.toArray(pendingTransactions.entries());
                _usedPaymentAddresses = _usedPaymentAddresses.toArray();
                totalVolume;
                lowestPriceSale;
                highestPriceSale;
                nextSubAccount;
                pendingDisbursements = List.toArray(pendingDisbursements);
            }
        };

        // Post upgrade

        private func _restore (
            backup : Types.Backup,
        ) : () {
            switch (backup.listings) {
                case (?x) {
                    listings := HashMap.HashMap<Ext.TokenIndex, Types.Listing>(
                        x.size(),
                        Ext.TokenIndex.equal,
                        Ext.TokenIndex.hash
                    );
                    for ((k, v) in x.vals()) listings.put(k, v);
                };
                case _ ();
            };
            switch (backup.transactions) {
                case (?x) {
                    for ((k, v) in x.vals()) transactions.put(k, v);
                };
                case _ ();
            };
            switch (backup.pendingTransactions) {
                case (?x) {
                    for ((k, v) in x.vals()) {
                        if (Time.now() < (v.initiated + transactionTtl)) {
                            pendingTransactions.put(k, v);
                        };
                    };
                };
                case _ ();
            };
            switch (backup._usedPaymentAddresses) {
                case (?x) {
                     for (x in x.vals()) _usedPaymentAddresses.add(x);
                };
                case _ ();
            };
            totalVolume := switch (backup.totalVolume) {
                case (?x) x;
                case _ totalVolume;
            };
            lowestPriceSale := switch (backup.lowestPriceSale) {
                case (?x) x;
                case _ lowestPriceSale;
            };
            highestPriceSale := switch (backup.highestPriceSale) {
                case (?x) x;
                case _ highestPriceSale;
            };
            nextSubAccount := switch (backup.nextSubAccount) {
                case (?x) x;
                case _ nextSubAccount;
            };
            pendingDisbursements := switch (backup.pendingDisbursements) {
                case (?x) List.fromArray<Types.Disbursement>(x);
                case _ pendingDisbursements;
            };
        };

        _restore({
            listings = ?state.listings;
            transactions = ?state.transactions;
            pendingTransactions = ?state.pendingTransactions;
            _usedPaymentAddresses = ?state._usedPaymentAddresses;
            totalVolume = ?state.totalVolume;
            lowestPriceSale = ?state.lowestPriceSale;
            highestPriceSale = ?state.highestPriceSale;
            nextSubAccount = ?state.nextSubAccount;
            pendingDisbursements = ?state.pendingDisbursements;
        });

        public func restore (
            caller : Principal,
            backup : Types.Backup,
        ) : () {
            assert state._Admins._isAdmin(caller);
            _restore(backup);
        };


        ///////////////
        // Hearbeat //
        /////////////


        // Process the queue of disbursements.
        var lastDisburseCron : Int = 0;
        var disburseInterval : Int = 10_000_000_000;
        public func cronDisbursements () : async () {

            // Let's try to save as many cycles on heartbeat as possible.
            if (List.size(pendingDisbursements) == 0) return;

            let now = Time.now();
            if (now - lastDisburseCron < disburseInterval) return;
            lastDisburseCron := now;

            // Keep track of completed and failed jobs.
            var completed   : List.List<Types.Disbursement> = null;
            var failed      : List.List<Types.Disbursement> = null;

            let next = List.pop<Types.Disbursement>(pendingDisbursements);
            var job = next.0;
            var remaining = next.1;

            label queue while (Option.isSome(job)) ignore do ? {
                try {
                    switch (
                        await nns.transfer({
                        fee = { e8s = 10_000; };
                        amount = { e8s = job!.3 };
                        memo = Nat64.fromNat(Nat32.toNat(job!.0));
                        from_subaccount = ?Blob.fromArray(job!.2);
                        created_at_time = null;
                        to = switch (Hex.decode(job!.1)) {
                            case(#ok(b)) Blob.fromArray(b);
                            case(#err(e)) {
                                state._log(state.cid, "cronDisbursements", "ERR :: Hex decode failure: " # e);
                                failed := List.push(job!, completed);
                                let next = List.pop(pendingDisbursements);
                                job := next.0;
                                remaining := next.1;
                                continue queue;
                            }
                        };
                    })
                ) {
                        case(#Ok(r)) {
                            completed := List.push(job!, completed);
                        };
                        case(#Err(e)) {
                            state._log(state.cid, "cronDisbursements", "ERR :: NNS Failure.");
                            failed := List.push(job!, completed);
                        };
                    };
                } catch (e) {
                    state._log(state.cid, "cronDisbursements", "ERR :: NNS Failure: " # Error.message(e));
                    failed := List.push(job!, completed);
                };
                
                let next = List.pop(pendingDisbursements);
                job := next.0;
                remaining := next.1;
            };

            // Put failed mints back in the queue.
            pendingDisbursements := failed;

        public func disbursements (
            caller : Principal
        ) : [Types.Disbursement] {
            assert(state._Admins._isAdmin(caller));
            List.toArray(pendingDisbursements);
        };

        // Trawl for pending transactions that we can settle.
        var lastSettleCron : Int = 0;
        var settleInterval : Int = 60_000_000_000;
        public func cronSettlements () : async () {
            let now = Time.now();
            if (now - lastSettleCron < settleInterval) return;
            lastSettleCron := now;
            for ((index, tx) in pendingTransactions.entries()) {
                ignore await settle(state.cid, tx.token);
            };
        };


        ///////////////////////
        // Internal / Utils //
        /////////////////////


        // Retrieve listing for a token.
        public func _getListing (
            index : Ext.TokenIndex,
        ) : ?Types.Listing {
            listings.get(index)
        };
        
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
            caller : Principal,
            token : Ext.TokenIdentifier,
        ) : async Result.Result<(), Ext.CommonError> {

            // Decode token index.
            let index = switch (Ext.TokenIdentifier.decode(token)) {
                case (#err(_)) { return #err(#InvalidToken(token)); };
                case (#ok(_, tokenIndex)) { tokenIndex; };
            };

            switch (pendingTransactions.get(index)) {
                case (?tx) {
                    // Attempt to settle the pending transaction.
                    switch (await settle(caller, token)) {
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

        // Convert incrementing sub account to a proper Blob.
        func _natToSubAccount(n : Nat) : Ext.SubAccount {
            let n_byte = func(i : Nat) : Nat8 {
                assert(i < 32);
                let shift : Nat = 8 * (32 - 1 - i);
                Nat8.fromIntWrap(n / 2**shift)
            };
            Array.tabulate<Nat8>(32, n_byte)
        };

        // Get and increment next subaccount.
        func _getNextSubAccount() : Ext.SubAccount {
            var _saOffset = 4294967296;
            nextSubAccount += 1;
            return _natToSubAccount(_saOffset + nextSubAccount);
        };

        // Queue a disbursement
        func _addDisbursement(d : Types.Disbursement) : () {
            pendingDisbursements := List.push(d, pendingDisbursements);
        };


        ////////////////
        // Admin API //
        //////////////


        public func readPending (
            caller  : Principal,
        ) : [(Ext.TokenIndex, Types.Transaction)] {
            assert(state._Admins._isAdmin(caller));
            Iter.toArray(pendingTransactions.entries());
        };

        public func paymentsRaw (
            caller  : Principal,
        ) : [(Nat, Types.Transaction)] {
            assert(state._Admins._isAdmin(caller));
            Iter.toArray(transactions.entries());
        };

        public func deleteListing (
            caller  : Principal,
            index   : Ext.TokenIndex,
        ) : () {
            assert(state._Admins._isAdmin(caller));
            listings.delete(index);
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
                case (#err(_)) {
                    return #err(#InvalidToken(request.token));
                };
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
            switch (await _canSettle(caller, request.token)) {
                case (#err(e)) {
                    return #err(e);
                };
                case _ ();
            };

            // NOTE: The interface to delete a listing is not explicit enough for my taste.
            switch (request.price) {
                // Create the listing.
                case (?price) {
                    listings.put(index, {
                        locked      = null;
                        seller      = caller;
                        subaccount  = null;
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
            var floor : Nat64 = 0;
            for (a in listings.entries()){
                if (floor == 0 or a.1.price < floor) floor := a.1.price;
            };
            (
                totalVolume,
                highestPriceSale,
                lowestPriceSale,
                floor,
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
            deprecated : [Nat8],
        ) : async Types.LockResponse {

            // Decode token index from token identifier.
            let index : Ext.TokenIndex = switch (_unpackTokenIdentifier(token)) {
                case (#ok(i)) i;
                case (#err(e)) {
                    state._log(caller, "list", token # " :: ERR :: Invalid token");
                    return #err(e);
                };
            };

            // Ensure token is not already locked.
            if (_isLocked(index)) {
                state._log(caller, "list", token # " :: ERR :: Already locked");
                return #err(#Other("Already locked."));
            };

            // Retrieve the token's listing.
            switch (listings.get(index)) {
                case (null) {
                    state._log(caller, "list", token # " :: ERR :: No such listing");
                    #err(#Other("No such listing."));
                };

                case (?listing) {

                    // Double check listing price
                    if (price != listing.price) {
                        state._log(caller, "list", token # " :: ERR :: Wrong price");
                        return #err(#Other("Incorrect listing price."));
                    };

                    let subaccount = _getNextSubAccount();
                    let paymentAddress : Ext.AccountIdentifier = Ext.AccountIdentifier.fromPrincipal(state.cid, ?subaccount);

                    // Lock the listing
                    listings.put(index, {
                        subaccount  = ?subaccount;
                        price       = listing.price;
                        seller      = listing.seller;
                        locked      = ?(Time.now() + transactionTtl);
                    });

                    // TODO: In the event that a balance of ICP is "stuck," what can we do? Doesn't the seller have control of it?

                    // Ensure there isn't a pending transaction which can be settled.
                    switch (await _canSettle(caller, token)) {
                        case (#err(e)) {
                            state._log(caller, "list", token # " :: ERR :: Pending settlement completed");
                            return #err(e);
                        };
                        case _ ();
                    };

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
                        bytes       = subaccount;
                    });
                    nextTxId += 1;  // Don't forget this 😬

                    state._log(caller, "list", token # " :: OK");

                    #ok(paymentAddress);
                    
                };
            };
        };

        // As the final step, after transfering ICP, we can settle the transaction.
        public func settle (
            caller  : Principal,
            token   : Ext.TokenIdentifier,
        ) : async Result.Result<(), Ext.CommonError> {
            // Decode token index from token identifier.
            let index : Ext.TokenIndex = switch (_unpackTokenIdentifier(token)) {
                case (#ok(i)) i;
                case (#err(e)) {
                    state._log(caller, "settle", token # " :: ERR :: Invalid token");
                    return #err(e);
                };
            };

            // Retrieve the pending transaction.
            let transaction = switch (pendingTransactions.get(index)) {
                case (?t) t;
                case _ {
                    state._log(caller, "settle", token # " :: ERR :: No such transaction");
                    return #err(#Other("No such pending transaction."));
                }
            };

            state._log(caller, "settle", token # " :: INFO :: Calling NNS");

            // Check the transaction account on the nns ledger canister.
            let balance = await state._Nns.balance(
                NNS.accountIdentifier(
                    state.cid,
                    Blob.fromArray(transaction.bytes),
                )
            );

            // Confirm enough funds have been sent.
            if (balance.e8s < transaction.price) {
                if (not _isLocked(index)) {
                    // This pending transaction is past its lock, so we delete it to save compute in our cron that iterates pending transactions.
                    pendingTransactions.delete(index);
                };
                state._log(caller, "settle", token # " :: ERR :: Insufficient funds");
                return #err(#Other("Insufficient funds sent."));
            };

            // Schedule disbursements for the proceeds from this sale.
            var funds = balance.e8s;
            // Set aside funds for tx fees.
            let txFees : Nat64 = 10_000 * 1 + Nat64.fromNat(fees.size());
            funds -= txFees;
            // Pay the taxman/taxwoman.
            var remaining = funds;
            for ((recipient, pct) in fees.vals()) {
                let amount : Nat64 = funds * (pct / 100);
                _addDisbursement(index, recipient, transaction.bytes, amount);
                remaining -= amount;
            };
            // Pay the seller
            _addDisbursement(index, transaction.from, transaction.bytes, remaining);

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

            // Increment sales stats.
            totalVolume += transaction.price;
            lowestPriceSale := switch (transaction.price < lowestPriceSale) {
                case (true) transaction.price;
                case (false) lowestPriceSale;
            };
            highestPriceSale := switch (transaction.price > highestPriceSale) {
                case (true) transaction.price;
                case (false) highestPriceSale;
            };

            // Transfer the NFT.
            state._Tokens.transfer(
                index,
                transaction.from,
                transaction.to
            );

            // Remove the listing.
            listings.delete(index);

            state._log(caller, "settle", token # " :: INFO :: Calling CAP");

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

            state._log(caller, "settle", token # " :: OK");

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