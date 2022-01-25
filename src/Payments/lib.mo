import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Ext "mo:ext/Ext";
import Prim "mo:prim";

import NNS "../NNS/lib";
import NNSTypes "../NNS/types";
import Types "types";


module {


    public let price : Nat64 = 200_000_000;
    public let lockTtl = 300_000_000_000;  // Time for a transaction to complete (5 mins.)

    public class Factory (state : Types.State) {


        ////////////
        // State //
        //////////

        var nextTxId : Types.TxId = 0;
        public let purchases = HashMap.HashMap<Types.TxId, Types.Purchase>(
            state.purchases.size(),
            Nat32.equal,
            func (a) { a },
        );
        public let refunds = HashMap.HashMap<Types.TxId, Types.Refund>(
            state.refunds.size(),
            Nat32.equal,
            func (a) { a },
        );
        public let locks = HashMap.HashMap<Types.TxId, Types.Lock>(
            state.purchases.size(),
            Nat32.equal,
            func (a) { a },
        );

        // Pre Upgrade

        public func toStable () : {
            nextTxId    : Types.TxId;
            locks       : [(Types.TxId, Types.Lock)];
            purchases   : [(Types.TxId, Types.Purchase)];
            refunds     : [(Types.TxId, Types.Refund)];
        } {
            {
                nextTxId;
                locks       = Iter.toArray(locks.entries());
                purchases   = Iter.toArray(purchases.entries());
                refunds     = Iter.toArray(refunds.entries());
            }
        };

        // Post Upgrade

        private func _restore (
            backup : {
                nextTxId    : ?Types.TxId;
                locks       : ?[(Types.TxId, Types.Lock)];
                purchases   : ?[(Types.TxId, Types.Purchase)];
                refunds     : ?[(Types.TxId, Types.Refund)];
            }
        ) : () {
            switch (backup.nextTxId) {
                case (?x) nextTxId := x;
                case _ ();
            };

            switch (backup.locks) {
                case (?x) {
                    for ((k, v) in Iter.fromArray(x)) {
                        if (Time.now() < (v.lockedAt + lockTtl)) {
                            locks.put(k, v);
                        }
                    };
                };
                case _ ();
            };

            switch (backup.purchases) {
                case (?x) for ((k, v) in Iter.fromArray(x)) purchases.put(k, v);
                case _ ();
            };

            switch (backup.refunds) {
                case (?x) for ((k, v) in Iter.fromArray(x)) refunds.put(k, v);
                case _ ();
            };
        };

        public func restore (
            caller : Principal,
            backup : {
                nextTxId    : ?Types.TxId;
                locks       : ?[(Types.TxId, Types.Lock)];
                purchases   : ?[(Types.TxId, Types.Purchase)];
                refunds     : ?[(Types.TxId, Types.Refund)];
            }
        ) : () {
            assert(state._Admins._isAdmin(caller));
            _restore(backup);
        };

        _restore({
            nextTxId = ?state.nextTxId;
            locks = ?state.locks;
            purchases = ?state.purchases;
            refunds = ?state.refunds;
        });


        ///////////////////////
        // Utils / Internal //
        /////////////////////


        // Uppercase a string
        public func _upper (
            string : Text,
        ) : Text { Text.map(string, Prim.charToUpper); };

        // Get all valid locks.
        public func _getValidLocks () : [Nat32] {
            Array.map<(Types.TxId, Types.Lock), Nat32>(
                Array.filter<(Types.TxId, Types.Lock)>(
                    Iter.toArray(locks.entries()),
                    func (_, a) {
                        Time.now() < (a.lockedAt + lockTtl)
                    }
                ),
                func (_, x) {
                    x.token;
                }
            );
        };

        // Get lock for a user.
        public func _findLock (
            caller  : Principal,
        ) : ?Types.Lock {
            switch (
                Array.find<(Types.TxId, Types.Lock)>(
                    Iter.toArray<(Types.TxId, Types.Lock)>(locks.entries()),
                    func (_, a) {
                        a.buyer == caller
                    }
                )
            ) {
                case (?(_, lock)) ?lock;
                case _ null;
            }
        };

        // Get lock for a user and memo.
        public func _findLockWithMemo (
            caller  : Principal,
            memo    : Nat64,
        ) : ?Types.Lock {
            switch (
                Array.find<(Types.TxId, Types.Lock)>(
                    Iter.toArray<(Types.TxId, Types.Lock)>(locks.entries()),
                    func (_, a) {
                        a.memo == memo and a.buyer == caller
                    }
                )
            ) {
                case (?(_, lock)) ?lock;
                case _ null;
            }
        };

        // Find a purchase with a principal.
        public func _findPurchase (
            caller  : Principal,
            memo    : Nat64,
            height  : NNSTypes.BlockHeight,
        ) : ?Types.Purchase {
            switch (
                Array.find<(Types.TxId, Types.Purchase)>(
                    Iter.toArray<(Types.TxId, Types.Purchase)>(purchases.entries()),
                    func (_, a) {
                        a.memo == memo and a.buyer == caller and a.blockheight == height
                    }
                )
            ) {
                case (?(_, purchase)) ?purchase;
                case _ null;
            }
        };

        // Find a purchase with an account address.
        public func _findAccountPurchase (
            caller  : Text,
            memo    : Nat64,
            height  : NNSTypes.BlockHeight,
        ) : ?Types.Purchase {
            switch (
                Array.find<(Types.TxId, Types.Purchase)>(
                    Iter.toArray<(Types.TxId, Types.Purchase)>(purchases.entries()),
                    func (_, a) {
                        a.memo == memo and _upper(a.buyerAccount) == _upper(caller) and a.blockheight == height
                    }
                )
            ) {
                case (?(_, purchase)) ?purchase;
                case _ null;
            }
        };

        // Find a failed purchase with an account address.
        public func _findRefund (
            caller  : Text,
            memo    : Nat64,
            height  : NNSTypes.BlockHeight,
        ) : ?Types.Refund {
            switch (
                Array.find<(Types.TxId, Types.Refund)>(
                    Iter.toArray<(Types.TxId, Types.Refund)>(refunds.entries()),
                    func (_, a) {
                        a.transactions.original.memo == memo and _upper(a.buyer) == _upper(caller) and a.transactions.original.blockheight == height;
                    }
                )
            ) {
                case (?(_, refund)) ?refund;
                case _ null;
            }
        };


        /////////////////
        // Public API //
        ///////////////


        // Request a lock on a random unclaimed NFT for purchase.
        public func lock (
            caller  : Principal,
            memo    : Nat64,
        ) : async Result.Result<Types.TxId, Text> {
            switch (_findLock(caller)) {
                case (?lock) {
                    locks.delete(lock.id);
                };
                case _ ();
            };
            switch (
                await state._Tokens._getRandomMintIndex(
                    ?_getValidLocks()
                )
            ) {
                case (?token) {
                    let txId = nextTxId;
                    nextTxId += 1;
                    locks.put(txId, {
                        id          = txId;
                        buyer       = caller;
                        buyerAccount= NNS.defaultAccount(caller);
                        lockedAt    = Time.now();
                        token;
                        memo;
                    });
                    #ok(txId);
                };
                case _ #err("No tokens left to mint.");
            };
        };

        // Poll for purchase completion.
        public func notify (
            caller      : Principal,
            blockheight : NNSTypes.BlockHeight,
            memo        : Nat64,
            canister    : Principal,
        ) : async Result.Result<Ext.TokenIndex, Text> {
            switch (await state._Nns.block(blockheight)) {
                case (#Ok(block)) {
                    switch (block) {
                        case (#Err(_)) return #err("Some kind of block error");
                        case (#Ok(b)) {
                            if (b.transaction.memo != memo) {
                                return #err("Memo mismatch: " # Nat64.toText(memo) # ", " # Nat64.toText(b.transaction.memo));
                            };
                            switch (b.transaction.transfer) {
                                case (#Send(transfer)) {
                                    if (
                                        NNS.defaultAccount(canister) != _upper(transfer.to)
                                    ) {
                                        return #err("Incorrect transfer recipient: " # NNS.defaultAccount(canister) # ", " # _upper(transfer.to));
                                    } else if (
                                        NNS.defaultAccount(caller) != _upper(transfer.from)
                                    ) {
                                        return #err("Incorrect transfer sender: " # NNS.defaultAccount(caller) # ", " # _upper(transfer.from));
                                    } else if (transfer.amount.e8s < price) {
                                        return #err("Incorrect transfer amount.");
                                    };
                                    switch (_findLockWithMemo(caller, b.transaction.memo)) {
                                        case (?lock) {
                                            purchases.put(lock.id, {
                                                id          = lock.id;
                                                buyer       = lock.buyer;
                                                buyerAccount= NNS.defaultAccount(lock.buyer);
                                                token       = lock.token;
                                                memo        = lock.memo;
                                                price       = transfer.amount.e8s;
                                                lockedAt    = lock.lockedAt;
                                                closedAt    = Time.now();
                                                blockheight = blockheight;
                                            });
                                            locks.delete(lock.id);
                                            switch (
                                                state._Tokens._mint(
                                                    lock.token,
                                                    #principal(lock.buyer),
                                                    null,
                                                    // TODO: GET SUBACCOUNT
                                                    // switch (notification.from_subaccount) {
                                                    //     case (?sa) ?Blob.toArray(sa);
                                                    //     case _ null;
                                                    // }
                                                )
                                            ) {
                                                case (#ok(_)) {
                                                    // Insert transaction history event.
                                                    ignore await state._Cap.insert({
                                                        caller;
                                                        operation = "mint";
                                                        details = [
                                                            ("token", #Text(state._Tokens.tokenId(state.cid, lock.token))),
                                                            ("to", #Text(lock.buyerAccount)),
                                                            ("price_decimals", #U64(8)),
                                                            ("price_currency", #Text("ICP")),
                                                            ("price", #U64(price)),
                                                        ];
                                                    });
                                                    #ok(lock.token);
                                                };
                                                case (#err(_)) #err("Failed to mint.");
                                            };
                                        };
                                        case _ return #err("No such lock.");
                                    }
                                };
                                case (#Burn(_)) return #err("Incorrect transaction type.");
                                case (#Mint(_)) return #err("Incorrect transaction type.");
                            };
                        };
                    };
                };
                case (#Err(e)) return #err("Block lookup error: (" # Nat64.toText(blockheight) # ") " # e);
            };
        };

        public func getPrice () : Nat64 {
            price;
        };

        public func available () : Nat {
            state._Tokens._getUnminted().size();
        };

        // Bulk process a list of transactions from NNS in search of transactions that need to be refunded.
        // This could be validated onchain against the ledger in some cases, but for now we will just limit it to admins.
        // @auth: admin
        public func processRefunds (
            caller          : Principal,
            canister        : Principal,
            nnsTransactions : [Types.NNSTransaction],
        )  : async Result.Result<(), Text> {
            assert(state._Admins._isAdmin(caller));
            for (transaction in Iter.fromArray(nnsTransactions)) {
                let account = _upper(transaction.from);
                switch (_findAccountPurchase(account, transaction.memo, transaction.blockheight)) {
                    case (?p) ();
                    case _ {
                        switch (_findRefund(account, transaction.memo, transaction.blockheight)) {
                            case (?p) {};
                            case _ {
                                // Transaction not found in our canister.

                                // Issue refund.
                                switch (await state._Nns.transfer(
                                    caller,
                                    { e8s = transaction.amount; },
                                    account,
                                    transaction.memo,
                                )) {
                                    case (#Ok(refundheight)) {
                                        // Record failure.
                                        let txId = nextTxId;
                                        nextTxId += 1;
                                        refunds.put(txId, {
                                            id           = txId;
                                            buyer        = account;
                                            transactions = {
                                                original = {
                                                    blockheight = transaction.blockheight;
                                                    from        = _upper(transaction.from);
                                                    amount      = transaction.amount;
                                                    memo        = transaction.memo;
                                                    timestamp   = transaction.timestamp;
                                                };
                                                refund = {
                                                    blockheight = refundheight;
                                                    from        = NNS.defaultAccount(canister);
                                                    amount      = transaction.amount;
                                                    memo        = transaction.memo;
                                                    timestamp   = Time.now();
                                                };
                                            };
                                        });
                                    };
                                    case (#Err(error)) {
                                        switch (error) {
                                            case (#BadFee(_)) return #err("Bad fee.");
                                            case (#InsufficientFunds(_)) return #err("Insufficient funds.");
                                            case (#TxCreatedInFuture(_)) return #err("Tx from future.");
                                            case (#TxDuplicate(_)) return #err("Duplicate tx.");
                                            case (#TxTooOld(_)) return #err("Tx too old.");
                                        };
                                    };
                                };
                            };
                        };
                    };
                };
            };
            return #ok();
        };


        ///////////////////
        // Internal API //
        /////////////////

        //


        ////////////////
        // Admin API //
        //////////////


    };
};