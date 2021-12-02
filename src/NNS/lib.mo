import AccountIdentifier "mo:principal/AccountIdentifier";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Text "mo:base/Text";

import CRC32 "CRC32";
import SHA224 "SHA224";
import Types "types";


module {


    ////////////
    // Utils //
    //////////


    // Until Quint's account identifier method is fixed:
    func beBytes(n: Nat32) : [Nat8] {
        func byte(n: Nat32) : Nat8 {
            Nat8.fromNat(Nat32.toNat(n & 0xff))
        };
        [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)]
    };
    type Subaccount = Blob;
    public type AccountIdentifier = Blob;
    public func accountIdentifier(principal: Principal, subaccount: Subaccount) : AccountIdentifier {
        let hash = SHA224.Digest();
        hash.write([0x0A]);
        hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
        hash.write(Blob.toArray(Principal.toBlob(principal)));
        hash.write(Blob.toArray(subaccount));
        let hashSum = hash.sum();
        let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
        Blob.fromArray(Array.append(crc32Bytes, hashSum))
    };

    public func defaultSubaccount() : Subaccount {
        Blob.fromArrayMut(Array.init(32, 0 : Nat8))
    };


    public class Factory (state : Types.State) {

        ////////////
        // State //
        //////////


        /////////////////
        // Blocks API //
        ///////////////


        let blockProxy : Types.BlockProxy = actor("ockk2-xaaaa-aaaai-aaaua-cai");

        public func block (
            blockheight : Nat64,
        ) : async {
            #Ok : { #Ok : Types.Block; #Err : Types.CanisterId };
            #Err : Text;
        } {
            await blockProxy.block(blockheight);
        };


        ////////////////
        // Admin API //
        //////////////
        

        // Check the balance of this canister on the NNS ledger
        // @auth: admin
        public func balance(
            caller  : Principal,
            p       : Principal,
        ) : async Types.ICP {
            assert(state.admins._isAdmin(caller));
            let nns : Types.NNS = actor("ryjl3-tyaaa-aaaaa-aaaba-cai");
            await nns.account_balance({
                account = accountIdentifier(p, defaultSubaccount());
            })
        };

        // TODO: Transfer

    };

};