import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";

import Types "types";

module {

    public class Factory (state : Types.State) {

        ////////////
        // State //
        //////////


        var stableNotifications : [Types.TransactionNotification] = [];
        let notifications = Buffer.Buffer<Types.TransactionNotification>(stableNotifications.size());

        // Pre Upgrade

        public func toStable () : {
            notifications : [Types.TransactionNotification];
        } {
            {
                notifications = notifications.toArray();
            }
        };

        // Post Upgrade : Provision notifications from stable memory
        
        for (v in stableNotifications.vals()) {
            notifications.add(v);
        };

        // TODO: backup and restore


        //////////
        // API //
        ////////


        // @auth: nns ledger
        public func transaction_notification (
            caller  : Principal,
            args    : Types.TransactionNotification,
        ) : () {

            // We need to make sure that only the Ledger can call this endpoint
            let ledger = Principal.fromText("ryjl3-tyaaa-aaaaa-aaaba-cai");
            assert(caller == ledger);

            // Capture the transaction
            notifications.add(args);

        };

        // @auth: admin
        public func readNotifications (
            caller : Principal,
        ) : ([Types.TransactionNotification]) {
            assert(state.admins._isAdmin(caller));
            notifications.toArray();
        };

    };

};