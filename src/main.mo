// 3rd Party Imports

import AccountIdentifier "mo:principal/AccountIdentifier";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import Admins "Admins";
import AssetTypes "Assets/types";
import Assets "Assets";
import Entrepot "Entrepot";
import EntrepotTypes "Entrepot/types";
import Ext "mo:ext/Ext";
import ExtFactory "Ext";
import ExtTypes "Ext/types";
import Http "Http";
import HttpTypes "Http/types";
import Ledger "Ledger";
import LedgerTypes "Ledger/types";
import NNS "NNS";
import NNSTypes "NNS/types";
import Hex "NNS/Hex";
import Payments "Payments";
import PaymentsTypes "Payments/types";


shared ({ caller = creator }) actor class LegendsNFT() = canister {


    /////////////
    // Config //
    ///////////


    let supply = 100 + 17;


    ///////////////////
    // Stable State //
    /////////////////


    // Assets

    private stable var stableAssets : [AssetTypes.Record] = [];

    // Admins

    private stable var stableAdmins : [Principal] = [creator];

    // Ledger

    private stable var stableLedger : [?LedgerTypes.Token] = Array.tabulate<?LedgerTypes.Token>(supply, func (i) { null });
    private stable var stableLegends : [LedgerTypes.Legend] = [];

    // Entrepot

    private stable var stableListings : [(Ext.TokenIndex, EntrepotTypes.Listing)] = [];
    private stable var stableTransactions : [(Nat, EntrepotTypes.Transaction)] = [];
    private stable var stablePendingTransactions : [(Ext.TokenIndex, EntrepotTypes.Transaction)] = [];

    // Payments

    private stable var stablePaymentsLocks : [(PaymentsTypes.TxId, PaymentsTypes.Lock)] = [];
    private stable var stablePaymentsPurchases : [(PaymentsTypes.TxId, PaymentsTypes.Purchase)] = [];
    private stable var stablePaymentsNextTxId : PaymentsTypes.TxId = 0;
    private stable var stablePaymentsRefunds : [(PaymentsTypes.TxId, PaymentsTypes.Refund)] = [];

    // Upgrades

    system func preupgrade() {

        // Preserve assets
        stableAssets := assets.toStable();

        // Preserve admins
        stableAdmins := admins.toStable();

        // Preserve ledger
        let { ledger = x; legends } = ledger.toStable();
        stableLedger := x;

        // Preserve legends
        stableLegends := legends;

        // Preserve entrepot
        let {
            listings;
            transactions;
            pendingTransactions;
        } = entrepot.toStable();
        stableListings              := listings;
        stableTransactions          := transactions;
        stablePendingTransactions   := pendingTransactions;

        // Preserve Payments
        let {
            locks;
            purchases;
            nextTxId;
            refunds;
        } = payments.toStable();
        stablePaymentsLocks     := locks;
        stablePaymentsPurchases := purchases;
        stablePaymentsRefunds   := refunds;
        stablePaymentsNextTxId  := nextTxId;

    };

    system func postupgrade() {
        // Yeet
    };


    /////////////
    // Admins //
    ///////////


    let admins = Admins.Admins({
        admins = stableAdmins;
    });

    public shared ({ caller }) func addAdmin (
        p : Principal,
    ) : async () {
        admins.addAdmin(caller, p);
    };

    public query ({ caller }) func isAdmin (
        p : Principal,
    ) : async Bool {
        admins.isAdmin(caller, p);
    };

    
    /////////////
    // Assets //
    ///////////


    let assets = Assets.Assets({
        admins;
        assets = stableAssets;
    });

    // Admin API

    public shared ({ caller }) func upload (
        bytes : [Blob],
    ) : async () {
        assets.upload(caller, bytes);
    };

    public shared ({ caller }) func uploadFinalize (
        contentType : Text,
        meta        : AssetTypes.Meta,
    ) : async Result.Result<(), Text> {
        assets.uploadFinalize(
            caller,
            contentType,
            meta,
        );
    };

    public shared ({ caller }) func uploadClear () : async () {
        assets.uploadClear(caller);
    };

    public shared ({ caller }) func purgeAssets (
        confirm : Text,
        tag     : ?Text,
    ) : async Result.Result<(), Text> {
        assets.purge(caller, confirm, tag);
    };


    /////////////
    // Ledger //
    ///////////


    let ledger = Ledger.Ledger({
        supply;
        admins;
        assets;
        ledger = stableLedger;
        legends = stableLegends;
    });

    public shared func readLedger () : async [?LedgerTypes.Token] {
        ledger.read(null);
    };

    public shared ({ caller }) func mint (
        to : Ext.User,
    ) : async Result.Result<Nat, Text> {
        ledger.mint(caller, to);
    };

    public shared ({ caller }) func configureLegends (
        conf : [LedgerTypes.Legend],
    ) : async Result.Result<(), Text> {
        ledger.configureLegends(caller, conf);
    };

    public shared ({ caller }) func ledgerReassign (
        token   : Ext.TokenIdentifier,
        to      : Ext.User,
        confirm : Text,
    ) : async Result.Result<(), Text> {
        ledger.reassign(caller, token, to, confirm);
    };

    public query ({ caller }) func ledgerBackup () : async [?LedgerTypes.Token] {
        ledger.backup(caller);
    };

    public shared ({ caller }) func ledgerRestore (
        data : [?LedgerTypes.Token],
    ) : async Result.Result<(), Text> {
        ledger.restore(caller, data);
    };


    //////////
    // EXT //
    ////////

    func _canisterPrincipal () : Principal {
        Principal.fromActor(canister);
    };

    let ext = ExtFactory.make({
        ledger;
    });

    public shared ({ caller }) func allowance(
        request : Ext.Allowance.Request,
    ) : async Ext.Allowance.Response {
        ext.allowance(caller, request);
    };
    
    public query ({ caller }) func metadata(
        tokenId : Ext.TokenIdentifier,
    ) : async Ext.Common.MetadataResponse {
        ext.metadata(caller, tokenId);
    };

    public shared ({ caller }) func approve(
        request : Ext.Allowance.ApproveRequest,
    ) : async () {
        ext.approve(caller, request);
    };

    public shared ({ caller }) func transfer(
        request : Ext.Core.TransferRequest,
    ) : async Ext.Core.TransferResponse {
        ext.transfer(caller, request);
    };

    public query ({ caller }) func tokens(
        accountId : Ext.AccountIdentifier
    ) : async Result.Result<[Ext.TokenIndex], Ext.CommonError> {
        ext.tokens(caller, accountId);
    };
    
    public query ({ caller }) func tokens_ext(
        accountId : Ext.AccountIdentifier
    ) : async Result.Result<[ExtTypes.TokenExt], Ext.CommonError> {
        ext.tokens_ext(caller, accountId)
    };

    public query func tokenId(
        index : Ext.TokenIndex,
    ) : async Ext.TokenIdentifier {
        ext.tokenId(_canisterPrincipal(), index);
    };


    ///////////////
    // Entrepot //
    /////////////

    let entrepot = Entrepot.Factory({
        admins;
        supply;
        ledger;
        listings            = stableListings;
        transactions        = stableTransactions;
        pendingTransactions = stablePendingTransactions;
    });

    public query func details (token : Ext.TokenIdentifier) : async EntrepotTypes.DetailsResponse {
        entrepot.details(token);
    };

    public query func listings () : async EntrepotTypes.ListingsResponse {
        entrepot.getListings();
    };

    public shared ({ caller }) func list (
        request : EntrepotTypes.ListRequest,
    ) : async EntrepotTypes.ListResponse {
        entrepot.list(caller, request);
    };

    public query func stats () : async (
        Nat64,  // Total Volume
        Nat64,  // Highest Price Sale
        Nat64,  // Lowest Price Sale
        Nat64,  // Current Floor Price
        Nat,    // # Listings
        Nat,    // # Supply
        Nat,    // #Sales
    ) {
        entrepot.stats();
    };

    public shared ({ caller }) func lock (
        token : Ext.TokenIdentifier,
        price : Nat64,
        buyer : Ext.AccountIdentifier,
        bytes : [Nat8],
    ) : async EntrepotTypes.LockResponse {
        entrepot.lock(caller, token, price, buyer, bytes);
    };

    public shared func settle (
        token : Ext.TokenIdentifier,
    ) : async Result.Result<(), Ext.CommonError> {
        entrepot.settle(token);
    };

    public shared ({ caller }) func purgeListings (
        confirm : Text,
    ) : async Result.Result<(), Text> {
        entrepot.purgeListings(caller, confirm);
    };


    //////////
    // NNS //
    ////////


    let nns = NNS.Factory({ admins; });
    
    public query func address () : async (Blob, Text) {
        let a = NNS.accountIdentifier(Principal.fromActor(canister), NNS.defaultSubaccount());
        (a, Hex.encode(Blob.toArray(a)));
    };

    public shared ({ caller }) func balance () : async NNSTypes.ICP {
        await nns.balance(caller, _canisterPrincipal());
    };


    ///////////////
    // Payments //
    /////////////


    let payments = Payments.Factory({
        admins;
        nns;
        ledger;
        locks       = stablePaymentsLocks;
        purchases   = stablePaymentsPurchases;
        refunds     = stablePaymentsRefunds;
        nextTxId    = stablePaymentsNextTxId;
    });

    public query func paymentsBackup () : async {
        nextTxId    : PaymentsTypes.TxId;
        locks       : [(PaymentsTypes.TxId, PaymentsTypes.Lock)];
        purchases   : [(PaymentsTypes.TxId, PaymentsTypes.Purchase)];
        refunds     : [(PaymentsTypes.TxId, PaymentsTypes.Refund)];
    } {
        payments.toStable();
    };

    public shared ({ caller }) func paymentsRestore (
        backup : {
            nextTxId    : ?PaymentsTypes.TxId;
            locks       : ?[(PaymentsTypes.TxId, PaymentsTypes.Lock)];
            purchases   : ?[(PaymentsTypes.TxId, PaymentsTypes.Purchase)];
            refunds     : ?[(PaymentsTypes.TxId, PaymentsTypes.Refund)];
        }
    ) : async () {
        payments.restore(caller, backup);
    };

    public shared ({ caller }) func paymentsLock (
        memo : Nat64,
    ) : async Result.Result<PaymentsTypes.TxId, Text> {
        await payments.lock(caller, memo);
    };

    public shared ({ caller }) func paymentsNotify (
        memo        : Nat64,
        blockheight : NNSTypes.BlockHeight,
    ) : async Result.Result<Ext.TokenIndex, Text> {
        await payments.notify(caller, blockheight, memo, _canisterPrincipal());
    };

    public query func paymentsGetPrice () : async Nat64 {
        payments.getPrice();
    };

    public query func paymentsGetAvailable () : async Nat {
        payments.available();
    };

    public shared ({ caller }) func paymentsProcessRefunds (
        transactions : [PaymentsTypes.NNSTransaction],
    ) : async Result.Result<(), Text> {
        await payments.processRefunds(caller, Principal.fromActor(canister), transactions);
    };


    ///////////
    // HTTP //
    /////////


    let httpHandler = Http.HttpHandler({
        assets;
        admins;
        entrepot;
        ledger;
        supply;
        payments;
    });

    public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
        httpHandler.request(request);
    };

};
