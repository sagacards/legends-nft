import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";

import Types "types";


module {


    public class Factory (state : Types.State) {


        ////////////
        // State //
        //////////

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


        // Pre Upgrade

        public func toStable () : {
            purchases   : [(Types.TxId, Types.Purchase)];
            refunds     : [(Types.TxId, Types.Refund)];
        } {
            {
                purchases   = Iter.toArray(purchases.entries());
                refunds     = Iter.toArray(refunds.entries());
            }
        };

        // Post Upgrade

        private func _restore (
            backup : {
                purchases   : ?[(Types.TxId, Types.Purchase)];
                refunds     : ?[(Types.TxId, Types.Refund)];
            }
        ) : () {

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
                purchases   : ?[(Types.TxId, Types.Purchase)];
                refunds     : ?[(Types.TxId, Types.Refund)];
            }
        ) : () {
            assert(state._Admins._isAdmin(caller));
            _restore(backup);
        };

        _restore({
            purchases = ?state.purchases;
            refunds = ?state.refunds;
        });

    };
};