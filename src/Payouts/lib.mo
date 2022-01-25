import AccountIdentifier "mo:base/Array";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Int "mo:base/Int";
import Int64 "mo:base/Int64";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";

import EvictingQueue "mo:queue/EvictingQueue";
import Ext "mo:ext/Ext";

import EntrepotTypes "../Entrepot/types";
import NNSTypes "../NNS/types";
import PaymentTypes "../Payments/types";
import Types "types";


module {

    public class Factory (state : Types.State) {


        /////////////
        // Config //
        ///////////


        let float : Nat64 = 100_000_000;  // 1 ICP e8s

        let distribution : [(Text, Float)] = [
            ("Holders",     10.0),
            ("Developers",  90.0),
        ];


        ////////////
        // State //
        //////////


        let manifests = EvictingQueue.EvictingQueue<Types.Manifest>(10);


        ////////////////
        // Internals //
        //////////////


        // Find all holders and the number of NFTs they hold.
        public func _getHolders () : [(Ext.AccountIdentifier, Nat)] {
            let holders = HashMap.HashMap<Ext.AccountIdentifier, Nat>(0, Ext.AccountIdentifier.equal, Ext.AccountIdentifier.hash);
            for (holder in state._Tokens.read(null).vals()) {
                switch (holder) {
                    case (?h) {
                        switch (holders.get(h.owner)) {
                            case (?x) holders.put(h.owner, x + 1);
                            case _ holders.put(h.owner, 1);
                        };
                    };
                    case _ ();
                }
            };
            Iter.toArray(holders.entries());
        };

        // Get developer addresses.
        public func _getDevelopers () : [(Text, Nat64)] {
            [
                ("2ca469ea9908a1562cdcb17c82d00f470db1f3c617ec1b2904bbea13c18c9447", 90),
                ("2ca469ea9908a1562cdcb17c82d00f470db1f3c617ec1asdfaf3f3ad133ddfa2", 10),
            ];
        };

        // Get cut of total distribution for label as a float.
        public func _getCut (
            tag : Text,
        ) : Float {
            let sum = Array.foldLeft<(Text, Float), Float>(distribution, 0, func (agg, (_, x)) { agg + x });
            let portion = switch(
                Array.find<(Text, Float)>(distribution, func ((x, _)) { x == tag })
            ) {
                case (?(_, p)) p;
                case _ 0.0;
            };
            portion / sum;
        };

        // Get cut of developer distribution.
        public func _getDeveloperCut (
            cut : Nat64
        ) : Float {
            Float.fromInt64(Int64.fromNat64(cut)) / Float.fromInt64(Int64.fromNat64(Array.foldLeft<(Text, Nat64), Nat64>(_getDevelopers(), 0, func (agg, (_, x)) { agg + x })));
        };

        // Create the plan of who will be paid what, which we can then execute against.
        public func _prepareManifest (
            canister    : Principal,
        ) : async Types.Manifest {
            let threshold : ?Time.Time = switch(manifests.peek()) {
                case (?m) ?m.timestamp;
                case _ null;
            };
            let timestamp = Time.now();
            let holders = _getHolders();
            let minted = state._Tokens._getMinted();
            let developers = _getDevelopers();
            let balance : NNSTypes.ICP = { e8s = 500_000_000 }; // await state._Nns.balance(canister);
            let amount : Nat64 = Nat64.max(balance.e8s - float, 0);
            
            let payouts : Buffer.Buffer<Types.Payout> = Buffer.Buffer(0);

            let holderCut = Int64.toNat64(Float.toInt64(_getCut("Holders") * Float.fromInt64(Int64.fromNat64(amount))));
            Debug.print("Holder cut: " # Nat64.toText(holderCut));
            for ((holder, count) in holders.vals()) {
                payouts.add({
                    recipient   = holder;
                    amount      = Int64.toNat64(Float.toInt64(
                        Float.fromInt64(Int64.fromNat64(holderCut)) * (
                            Float.fromInt64(Int64.fromNat64(Nat64.fromNat(count))) / Float.fromInt64(Int64.fromNat64(Nat64.fromNat(minted.size())))
                        )
                    ));
                    paid        = false;
                    blockheight = null;
                });
            };

            let developerCut = Int64.toNat64(Float.toInt64(_getCut("Developers") * Float.fromInt64(Int64.fromNat64(amount))));
            Debug.print("Developer cut: " # " " # Nat64.toText(developerCut));
            for ((developer, portion) in developers.vals()) {
                payouts.add({
                    recipient   = developer;
                    amount      = Int64.toNat64(Float.toInt64(Float.fromInt64(Int64.fromNat64(developerCut)) * _getDeveloperCut(portion)));
                    paid        = false;
                    blockheight = null;
                });
            };

            let manifest = {
                timestamp;
                amount = { e8s = amount };
                payouts = payouts.toArray();
            };
        };


        ////////////////
        // Admin API //
        //////////////


        // Send the money to the people.
        // @auth: admin... holder?
        public func payout (
            caller      : Principal,
            canister    : Principal,
        ) : async Types.Manifest {
            assert(state._Admins._isAdmin(caller));
            await _prepareManifest(canister);
        };

    };

};