import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Ext "mo:ext/Ext";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import NNSNotifyTypes "../NNSNotify/types";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Types "types";

module {


    public let price : Nat64 = 200_000_000;
    public let lockTtl = 300_000_000_000;  // Time for a transaction to complete (5 mins.)

    public class Factory (state : Types.State) {


        ////////////
        // State //
        //////////

        var nextTxId : Types.TxId = 0;
        let purchases = HashMap.HashMap<Types.TxId, Types.Purchase>(
            state.purchases.size(),
            Nat32.equal,
            func (a) { a },
        );
        let failedPurchases = HashMap.HashMap<Types.TxId, Types.Purchase>(
            state.purchases.size(),
            Nat32.equal,
            func (a) { a },
        );
        let locks = HashMap.HashMap<Types.TxId, Types.Lock>(
            state.purchases.size(),
            Nat32.equal,
            func (a) { a },
        );

        // Pre Upgrade

        public func toStable () : {
            nextTxId    : Types.TxId;
            locks       : [(Types.TxId, Types.Lock)];
            purchases   : [(Types.TxId, Types.Purchase)];
            failed      : [(Types.TxId, Types.Purchase)];
        } {
            {
                nextTxId;
                locks       = Iter.toArray(locks.entries());
                purchases   = Iter.toArray(purchases.entries());
                failed      = Iter.toArray(failedPurchases.entries());
            }
        };

        // Post Upgrade

        nextTxId := state.nextTxId;
        for ((k, v) in Iter.fromArray(state.locks)) {
            if (Time.now() < (v.lockedAt + lockTtl)) {
                locks.put(k, v);
            }
        };
        for ((k, v) in Iter.fromArray(state.purchases)) purchases.put(k, v);
        for ((k, v) in Iter.fromArray(state.failed)) failedPurchases.put(k, v);

        // TODO: Backup and restore


        ///////////////////////
        // Utils / Internal //
        /////////////////////


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
            memo    : NNSNotifyTypes.Memo,
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

        // Find a purchase.
        public func _findPurchase (
            caller  : Principal,
            memo    : NNSNotifyTypes.Memo,
        ) : ?Types.Purchase {
            switch (
                Array.find<(Types.TxId, Types.Purchase)>(
                    Iter.toArray<(Types.TxId, Types.Purchase)>(purchases.entries()),
                    func (_, a) {
                        a.memo == memo and a.buyer == caller
                    }
                )
            ) {
                case (?(_, purchase)) ?purchase;
                case _ null;
            }
        };


        /////////////////
        // Public API //
        ///////////////


        // Request a lock on a random unclaimed NFT for purchase.
        public func lock (
            caller  : Principal,
            memo    : NNSNotifyTypes.Memo,
        ) : async Result.Result<Types.TxId, Text> {
            switch (_findLock(caller)) {
                case (?lock) {
                    locks.delete(lock.id);
                };
                case _ ();
            };
            switch (
                await state.ledger._getRandomMintIndex(
                    ?_getValidLocks()
                )
            ) {
                case (?token) {
                    let txId = nextTxId;
                    nextTxId += 1;
                    locks.put(txId, {
                        id          = txId;
                        buyer       = caller;
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
        public func awaitTransaction (
            caller  : Principal,
            memo    : NNSNotifyTypes.Memo,
        ) : Result.Result<Ext.TokenIndex, {
            #pending    : Text;
            #notFound   : Text;
            #expired    : Text;
        }> {
            switch (_findPurchase(caller, memo)) {
                case (?purchase) #ok(purchase.token);
                case _ {
                    switch (_findLockWithMemo(caller, memo)) {
                        case (?lock) {
                            if (Time.now() < lock.lockedAt + lockTtl) {
                                #err(#pending("Awaiting transaction completion."));
                            } else {
                                #err(#expired("This lock has expired."));
                            };
                        };
                        case _ #err(#notFound("No such transaction."));
                    };
                    
                };
            };
        };

        public func getPrice () : Nat64 {
            price;
        };


        ///////////////////
        // Internal API //
        /////////////////

        // Capture a transaction notification from the NNS ledger.
        // If it corresponds to a pending lock, complete the transaction.
        public func _captureNotification (
            notification : NNSNotifyTypes.TransactionNotification
        ) : () {
            switch (_findLockWithMemo(notification.from, notification.memo)) {
                case (?lock) {
                    switch (notification.amount.e8s >= price) {
                        case (true) {
                            purchases.put(lock.id, {
                                id          = lock.id;
                                buyer       = lock.buyer;
                                token       = lock.token;
                                memo        = lock.memo;
                                price       = notification.amount.e8s;
                                lockedAt    = lock.lockedAt;
                                closedAt    = Time.now();
                            });
                            locks.delete(lock.id);
                            switch (
                                state.ledger._mint(
                                    lock.token,
                                    #principal(lock.buyer),
                                    switch (notification.from_subaccount) {
                                        case (?sa) ?Blob.toArray(sa);
                                        case _ null;
                                    }
                                )
                            ) {
                                case (#ok(_)) ();
                                case (#err(_)) ();
                            };
                            return ();
                        };
                        case (false) {
                            // Add to failed payments
                            // Refund
                        };
                    };
                };
                case _ {
                    // Feels like maybe we need a way to issue a refund when receiving funds for which no lock was secured.
                    // Difficulty is that there may be a lock in another module, so I can't make that call here.
                    // Maybe refactor into a single module for anticipated transactions.
                };
            };
        };


        ////////////////
        // Admin API //
        //////////////


        // TODO: Read payments
        // TODO: Read failed payments


    };
};