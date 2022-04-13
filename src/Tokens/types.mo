import List "mo:base/List";

import Cap "mo:cap/Cap";
import Ext "mo:ext/Ext";

import Admins "../Admins";
import Assets "../Assets";


module {

    // We are inbetween standards. Development started on EXT, but we are slowly transitioning to DIP721. This flag is used to determine which datastructures to use, allowing us to manage the process of migrating old canister state to new structures.
    public type LedgerVersion = {
        #Version1;
        #Version2;
    };

    public type Deps = {
        _Admins     : Admins.Admins;
        _Assets     : Assets.Assets;
        _Cap        : Cap.Cap;
        _log        : (caller  : Principal, method  : Text, message : Text,) -> ();
        cid         : Principal;
        supply      : Nat16;
    };

    public type State = {
        isShuffled  : Bool;
        // V1
        tokens      : [?Token];
        metadata    : [Metadata];
        // V2
        tokensV2    : [TokenMetadata];
    };

    public type Params = State and Deps;

    ///////////////
    // V1: ~EXT //
    /////////////

    public type Metadata = {
        back    : Text;
        border  : Text;
        ink     : Text;
    };

    public type TokenIndex = Nat32;

    public type Token = {
        createdAt  : Int;
        owner      : Ext.AccountIdentifier;
        txId       : Text;
    };
    

    /////////////////
    // V2: DIP721 //
    ///////////////

    public type InitArgs = {
        name : ?Text;
        logo : ?Text;
        symbol: ?Text;
        custodians: List.List<Principal>; // HashSet in rust = ? in motoko?
    };

    public type CanisterMetadata = {
        name: ?Text;
        logo: ?Text;
        symbol: ?Text;
        custodians: List.List<Principal>;
        createdAt: Nat64;
        upgradedAt: Nat64;
    };

    public type Stats = {
        totalTransactions: Nat;
        totalSupply: Nat;
        cycles: Nat;
        totalUniqueHolders: Nat;
    };

    public type GenericValue = {
        #BoolContent: Bool;
        #TextContent: Text;
        #BlobContent: [Nat8];
        #Principal: Principal;
        #Nat8Content: Nat8;
        #Nat16Content: Nat16;
        #Nat32Content: Nat32;
        #Nat64Content: Nat64;
        #NatContent: Nat;
        #Int8Content: Int8;
        #Int16Content: Int16;
        #Int32Content: Int32;
        #Int64Content: Int64;
        #IntContent: Int;
        #FloatContent: Float; // motoko only support f4
        #NestedContent: [(Text, GenericValue)];
    };

    public type TokenIdentifier = Nat;

    public type TokenMetadata = {
        tokenIdentifier: TokenIdentifier;
        owner: ?Principal;
        operator: ?Principal;
        isBurned: Bool;
        properties: [(Text, GenericValue)];
        mintedAt: Nat64;
        mintedBy: Principal;
        transferredAt: ?Nat64;
        transferredBy: ?Principal;
        approvedAt: ?Nat64;
        approvedBy: ?Principal;
        burnedAt: ?Nat64;
        burnedBy: ?Principal;
    };

    public type TxEvent = {
        time: Nat64;
        caller: Principal;
        operation: Text;
        details: [(Text, GenericValue)];
    };

    public type SupportedInterface = {
        #Approval;
        #Mint;
        #Burn;
        #TransactionHistory;
    };

    public type NftError = {
        #UnauthorizedOwner;
        #UnauthorizedOperator;
        #OwnerNotFound;
        #OperatorNotFound;
        #TokenNotFound;
        #ExistedNFT;
        #SelfApprove;
        #SelfTransfer;
        #TxNotFound;
        #Other: Text;
    };

};