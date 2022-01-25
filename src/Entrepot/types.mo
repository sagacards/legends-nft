import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Cap "mo:cap/Cap";
import Ext "mo:ext/Ext";

import Admins "../Admins";
import Tokens "../Tokens";
import NNS "../NNS";

module {

    public type SubAccount = [Nat8];

    public type State = {
        _Admins                 : Admins.Admins;
        _Cap                    : Cap.Cap;
        _Tokens                 : Tokens.Factory;
        _Nns                    : NNS.Factory;
        supply                  : Nat16;
        listings                : [(Ext.TokenIndex, Listing)];
        transactions            : [(Nat, Transaction)];
        pendingTransactions     : [(Ext.TokenIndex, Transaction)];
        _usedPaymentAddresses   : [(Ext.AccountIdentifier, Principal, Ext.SubAccount)];
        cid                     : Principal;
    };

    public type Listing = {
        // 6 extra digits
        // javascript   : 1_637_174_793_714
        // motoko       : 1_637_174_793_714_948_574)
        locked      : ?Time.Time;
        price       : Nat64;  // ICPe8
        seller      : Principal;
        subaccount  : ?Ext.SubAccount;
    };

    public type ExtListing = {
        locked      : ?Time.Time;
        price       : Nat64;  // ICPe8
        seller      : Principal;
    };

    public type Metadata = {
        #fungible : {
            decimals    : Nat8;
            metadata    : ?Blob;
            name        : Text;
            symbol      : Text;
        };
        #nonfungible : {
            metadata : ?Blob;
        };
    };

    public type ListingsResponse = [(
        Ext.TokenIndex,
        ExtListing,
        Metadata,
    )];

    public type ListRequest = {
        from_subaccount  : ?Ext.SubAccount;
        price            : ?Nat64;  // ICPe8
        token            : Ext.TokenIdentifier;
    };
    
    public type ListResponse = Result.Result<(), Ext.CommonError>;

    // First tuple value is seller's account identifier
    // Perhaps distinct from Listing.seller as a destination wallet for proceeds?
    public type DetailsResponse = Result.Result<(Ext.AccountIdentifier, ?Listing), Ext.CommonError>;

    // WARNING: Oddly, using this type as a return type will give a function a different return signature
    // than if you were to use the same value inline (i.e. copy-paste-this.) Entrepot expects the signature
    // which results from the inline usage of this interface, so do that.
    public type StatsResponse = (
        Nat64,  // Total Volume
        Nat64,  // Highest Price Sale
        Nat64,  // Lowest Price Sale
        Nat64,  // Current Floor Price
        Nat,    // # Listings
        Nat,    // # Supply
        Nat,    // #Sales
    );

    public type Transaction = {
        id          : Nat;
        memo        : ?Blob;
        from        : Ext.AccountIdentifier;
        to          : Ext.AccountIdentifier;
        seller      : Principal;
        price       : Nat64;        // e8s
        initiated   : Time.Time;    // when it was locked lock
        closed      : ?Time.Time;    // when it was settled
        bytes       : [Nat8];
    };

    public type LockRequest = (
        token : Ext.TokenIdentifier,
        price : Nat64,
        buyer : Ext.AccountIdentifier,
        bytes : [Nat8],
    );

    // Returns the address to pay out to.
    public type LockResponse = Result.Result<Ext.AccountIdentifier, Ext.CommonError>;

};