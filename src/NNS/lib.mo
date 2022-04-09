import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Prim "mo:⛔";

import CRC32 "CRC32";
import Hex "Hex";
import SHA224 "SHA224";
import Types "types";


module {

    public class Factory (state : Types.State) {

        let nns : Types.NNS = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");

        /////////////////////
        // NNS Ledger API //
        ///////////////////
        

        public func balance(
            account : Blob,
        ) : async Types.ICP {
            await nns.account_balance({
                account;
            });
        };


        ////////////////
        // Admin API //
        //////////////

        // Transfer funds on nns ledger
        // @auth: admin
        public func transfer (
            caller  : Principal,
            amount  : Types.ICP,
            to      : Text,
            memo    : Types.Memo,
        ) : async Types.TransferResult {
            assert(state._Admins._isAdmin(caller));
            switch (Hex.decode(to)) {
                case (#ok(aid)) {
                    await nns.transfer({
                        fee = { e8s = 10_000; };
                        amount;
                        memo;
                        from_subaccount = null;
                        created_at_time = null;
                        to = Blob.fromArray(aid);
                    })
                };
                // TODO This error is horribly incorrect.
                case (#err(#msg(e))) {
                    Debug.print(e);
                    #Err(#TxCreatedInFuture(null));
                };
            };
        };

    };

};