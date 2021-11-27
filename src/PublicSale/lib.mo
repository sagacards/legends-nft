import AccountIdentifier "mo:principal/AccountIdentifier";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Debug "mo:base/Debug";
import Ext "mo:ext/Ext";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import NNS "../NNS/lib";
import NNSTypes "../NNS/types";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Types "types";
import Hex "../NNS/Hex";
import Prim "mo:prim";

module {


    public let price : Nat64 = 1;
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

        // Find a purchase.
        public func _findPurchase (
            caller  : Principal,
            memo    : Nat64,
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
            memo    : Nat64,
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
        public func notify (
            caller      : Principal,
            blockheight : NNSTypes.BlockHeight,
            memo        : Nat64,
            canister    : Principal,
        ) : async Result.Result<Ext.TokenIndex, Text> {
            switch (await state.nns.block(blockheight)) {
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
                                        Hex.encode(Blob.toArray(NNS.accountIdentifier(canister, NNS.defaultSubaccount()))) != Text.map(transfer.to, Prim.charToUpper)
                                    ) {
                                        return #err("Incorrect transfer recipient: " # Hex.encode(Blob.toArray(NNS.accountIdentifier(canister, NNS.defaultSubaccount()))) # ", " # Text.map(transfer.to, Prim.charToUpper));
                                    } else if (
                                        Hex.encode(Blob.toArray(NNS.accountIdentifier(caller, NNS.defaultSubaccount()))) != Text.map(transfer.from, Prim.charToUpper)
                                    ) {
                                        return #err("Incorrect transfer sender: " # Hex.encode(Blob.toArray(NNS.accountIdentifier(caller, NNS.defaultSubaccount()))) # ", " # Text.map(transfer.from, Prim.charToUpper));
                                    } else if (transfer.amount.e8s < price) {
                                        return #err("Incorrect transfer amount.");
                                    };
                                    switch (_findLockWithMemo(caller, b.transaction.memo)) {
                                        case (?lock) {
                                            purchases.put(lock.id, {
                                                id          = lock.id;
                                                buyer       = lock.buyer;
                                                token       = lock.token;
                                                memo        = lock.memo;
                                                price       = transfer.amount.e8s;
                                                lockedAt    = lock.lockedAt;
                                                closedAt    = Time.now();
                                            });
                                            locks.delete(lock.id);
                                            switch (
                                                state.ledger._mint(
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
                                                case (#ok(_)) #ok(lock.token);
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


        ///////////////////
        // Internal API //
        /////////////////

        //


        ////////////////
        // Admin API //
        //////////////


        // TODO: Read payments
        // TODO: Read failed payments


    };
};