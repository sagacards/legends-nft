import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Cap "mo:cap/Cap";
import CapRouter "mo:cap/Router";
import EXT "mo:ext/Ext";

import Admins "Admins";
import AssetTypes "Assets/types";
import Assets "Assets";
import Entrepot "Entrepot";
import EntrepotTypes "Entrepot/types";
import Ext "Ext";
import ExtTypes "Ext/types";
import Hex "NNS/Hex";
import Http "Http";
import HttpTypes "Http/types";
import NNS "NNS";
import NNSTypes "NNS/types";
import Payments "Payments";
import PaymentsTypes "Payments/types";
import Payouts "Payouts";
import PayoutsTypes "Payouts/types";
import TokenTypes "Tokens/types";
import Tokens "Tokens";


shared ({ caller = creator }) actor class LegendsNFT(
    // This must be the canister's own principal. It sucks having to do this, but I don't know a better way to enable passing a self reference to a submodule in Motoko.
    cid         : Principal,
    capRouter   : ?Text,
    canisterMeta: {
        supply      : Nat16;
        name        : Text;
        flavour     : Text;
        description : Text;
        artists     : [Text];
    },
) = {


    ///////////////////
    // Stable State //
    /////////////////


    // Config

    private stable var nri : [(Text, Float)] = [];

    // CAP

    private stable var capRoot : ?Text = null;

    // Assets

    private stable var stableAssets : [AssetTypes.Record] = [];

    // Admins

    private stable var stableAdmins : [Principal] = [creator];

    // Ledger

    private stable var stableTokens : [?TokenTypes.Token] = Array.tabulate<?TokenTypes.Token>(Nat16.toNat(canisterMeta.supply), func (i) { null });
    private stable var stableLegends : [TokenTypes.Legend] = [];

    // Entrepot

    private stable var stableListings : [(EXT.TokenIndex, EntrepotTypes.Listing)] = [];
    private stable var stableTransactions : [(Nat, EntrepotTypes.Transaction)] = [];
    private stable var stablePendingTransactions : [(EXT.TokenIndex, EntrepotTypes.Transaction)] = [];
    private stable var stableUsedPaymentAddress : [(EXT.AccountIdentifier, Principal, EXT.SubAccount)] = [];

    // Payments

    private stable var stablePaymentsLocks : [(PaymentsTypes.TxId, PaymentsTypes.Lock)] = [];
    private stable var stablePaymentsPurchases : [(PaymentsTypes.TxId, PaymentsTypes.Purchase)] = [];
    private stable var stablePaymentsNextTxId : PaymentsTypes.TxId = 0;
    private stable var stablePaymentsRefunds : [(PaymentsTypes.TxId, PaymentsTypes.Refund)] = [];

    // Upgrades

    system func preupgrade() {

        // Preserve assets
        stableAssets := _Assets.toStable();

        // Preserve admins
        stableAdmins := _Admins.toStable();

        // Preserve token ledger
        let { tokens = x; legends } = _Tokens.toStable();
        stableTokens := x;

        // Preserve legends
        stableLegends := legends;

        // Preserve entrepot
        let {
            listings;
            transactions;
            pendingTransactions;
            _usedPaymentAddresses
        } = _Entrepot.toStable();
        stableListings              := listings;
        stableTransactions          := transactions;
        stablePendingTransactions   := pendingTransactions;
        stableUsedPaymentAddress    := _usedPaymentAddresses;

        // Preserve Payments
        let {
            locks;
            purchases;
            nextTxId;
            refunds;
        } = _Payments.toStable();
        stablePaymentsLocks     := locks;
        stablePaymentsPurchases := purchases;
        stablePaymentsRefunds   := refunds;
        stablePaymentsNextTxId  := nextTxId;

    };

    system func postupgrade() {
        // Yeet
    };


    //////////
    // CAP //
    ////////


    let capRouterId = Option.get(capRouter, CapRouter.mainnet_id);
    let _Cap = Cap.Cap(?capRouterId, capRoot);


    /////////////
    // Admins //
    ///////////


    let _Admins = Admins.Admins({
        admins = stableAdmins;
    });

    // This needs to be manually called once after canister creation.
    public shared ({ caller }) func init () : async Result.Result<(), Text> {
        assert(_Admins._isAdmin(caller));
        // Initialize CAP and store root bucket id
        capRoot := await _Cap.handshake(
            Principal.toText(cid),
            1_000_000_000_000,
        );
        #ok();
    };

    public shared ({ caller }) func configureNri (
        data : [(Text, Float)],
    ) : async () {
        assert(_Admins._isAdmin(caller));
        nri := data;
        _HttpHandler.updateNri(data);
    };

    public shared ({ caller }) func addAdmin (
        p : Principal,
    ) : async () {
        _Admins.addAdmin(caller, p);
    };

    public query ({ caller }) func isAdmin (
        p : Principal,
    ) : async Bool {
        _Admins.isAdmin(caller, p);
    };

    public shared ({ caller }) func removeAdmin (
        p : Principal,
    ) : async () {
        _Admins.removeAdmin(caller, p);
    };

    public query func getAdmins () : async [Principal] {
        _Admins.getAdmins();
    };

    
    /////////////
    // Assets //
    ///////////


    let _Assets = Assets.Assets({
        _Admins;
        assets = stableAssets;
    });

    public shared ({ caller }) func upload (
        bytes : [Blob],
    ) : async () {
        _Assets.upload(caller, bytes);
    };

    public shared ({ caller }) func uploadFinalize (
        contentType : Text,
        meta        : AssetTypes.Meta,
    ) : async Result.Result<(), Text> {
        _Assets.uploadFinalize(
            caller,
            contentType,
            meta,
        );
    };

    public shared ({ caller }) func uploadClear () : async () {
        _Assets.uploadClear(caller);
    };

    public shared ({ caller }) func purgeAssets (
        confirm : Text,
        tag     : ?Text,
    ) : async Result.Result<(), Text> {
        _Assets.purge(caller, confirm, tag);
    };


    /////////////
    // Tokens //
    ///////////


    let _Tokens = Tokens.Factory({
        _Admins;
        _Assets;
        _Cap;
        tokens  = stableTokens;
        legends = stableLegends;
        supply  = canisterMeta.supply;
        cid;
    });

    public shared func readLedger () : async [?TokenTypes.Token] {
        _Tokens.read(null);
    };

    public shared ({ caller }) func mint (
        to : EXT.User,
    ) : async Result.Result<Nat, Text> {
        await _Tokens.mint(caller, to);
    };

    public shared ({ caller }) func configureLegends (
        conf : [TokenTypes.Legend],
    ) : async Result.Result<(), Text> {
        _Tokens.configureLegends(caller, conf);
    };

    public query ({ caller }) func tokensBackup () : async [?TokenTypes.Token] {
        _Tokens.backup(caller);
    };

    public shared ({ caller }) func tokensRestore (
        data : [?TokenTypes.Token],
    ) : async Result.Result<(), Text> {
        _Tokens.restore(caller, data);
    };


    //////////
    // EXT //
    ////////


    let _Ext = Ext.make({
        _Tokens;
        _Cap;
        cid;
    });

    public shared ({ caller }) func allowance(
        request : EXT.Allowance.Request,
    ) : async EXT.Allowance.Response {
        _Ext.allowance(caller, request);
    };
    
    public query ({ caller }) func metadata(
        tokenId : EXT.TokenIdentifier,
    ) : async EXT.Common.MetadataResponse {
        _Ext.metadata(caller, tokenId);
    };

    public shared ({ caller }) func approve(
        request : EXT.Allowance.ApproveRequest,
    ) : async () {
        _Ext.approve(caller, request);
    };

    public shared ({ caller }) func transfer(
        request : EXT.Core.TransferRequest,
    ) : async EXT.Core.TransferResponse {
        await _Ext.transfer(caller, request);
    };

    public query ({ caller }) func tokens(
        accountId : EXT.AccountIdentifier
    ) : async Result.Result<[EXT.TokenIndex], EXT.CommonError> {
        _Ext.tokens(caller, accountId);
    };
    
    public query ({ caller }) func tokens_ext(
        accountId : EXT.AccountIdentifier
    ) : async Result.Result<[(EXT.TokenIndex, ?EntrepotTypes.Listing, ?[Nat8])], EXT.CommonError> {
        _Entrepot.tokens_ext(caller, accountId)
    };

    public query func tokenId(
        index : EXT.TokenIndex,
    ) : async EXT.TokenIdentifier {
        _Ext.tokenId(cid, index);
    };


    //////////
    // NNS //
    ////////


    let _Nns = NNS.Factory({
        _Admins;
    });
    
    public query func address () : async (Blob, Text) {
        let a = NNS.accountIdentifier(cid, NNS.defaultSubaccount());
        (a, Hex.encode(Blob.toArray(a)));
    };

    public shared ({ caller }) func balance () : async NNSTypes.ICP {
        await _Nns.balance(NNS.accountIdentifier(cid, NNS.defaultSubaccount()));
    };

    public shared ({ caller }) func nnsTransfer (
        amount  : NNSTypes.ICP,
        to      : Text,
        memo    : NNSTypes.Memo,
    ) : async NNSTypes.TransferResult {
        await _Nns.transfer(caller, amount, to, memo);
    };


    ///////////////
    // Entrepot //
    /////////////

    let _Entrepot = Entrepot.Factory({
        _Admins;
        _Cap;
        _Tokens;
        _Nns;
        listings            = stableListings;
        transactions        = stableTransactions;
        pendingTransactions = stablePendingTransactions;
        supply              = canisterMeta.supply;
        cid;
        _usedPaymentAddresses = stableUsedPaymentAddress;
    });

    public query func details (token : EXT.TokenIdentifier) : async EntrepotTypes.DetailsResponse {
        _Entrepot.details(token);
    };

    public query func listings () : async EntrepotTypes.ListingsResponse {
        _Entrepot.getListings();
    };

    public shared ({ caller }) func list (
        request : EntrepotTypes.ListRequest,
    ) : async EntrepotTypes.ListResponse {
        await _Entrepot.list(caller, request);
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
        _Entrepot.stats();
    };

    public shared ({ caller }) func lock (
        token : EXT.TokenIdentifier,
        price : Nat64,
        buyer : EXT.AccountIdentifier,
        bytes : [Nat8],
    ) : async EntrepotTypes.LockResponse {
        await _Entrepot.lock(caller, token, price, buyer, bytes);
    };

    public shared func settle (
        token : EXT.TokenIdentifier,
    ) : async Result.Result<(), EXT.CommonError> {
        await _Entrepot.settle(token);
    };

    public query ({ caller }) func payments () : async ?[EXT.SubAccount] {
        _Entrepot.payments(caller);
    };


    ///////////////
    // Payments //
    /////////////


    let _Payments = Payments.Factory({
        _Admins;
        _Cap;
        _Nns;
        _Tokens;
        locks       = stablePaymentsLocks;
        purchases   = stablePaymentsPurchases;
        refunds     = stablePaymentsRefunds;
        nextTxId    = stablePaymentsNextTxId;
        cid;
    });

    public query func paymentsBackup () : async {
        nextTxId    : PaymentsTypes.TxId;
        locks       : [(PaymentsTypes.TxId, PaymentsTypes.Lock)];
        purchases   : [(PaymentsTypes.TxId, PaymentsTypes.Purchase)];
        refunds     : [(PaymentsTypes.TxId, PaymentsTypes.Refund)];
    } {
        _Payments.toStable();
    };

    public shared ({ caller }) func paymentsRestore (
        backup : {
            nextTxId    : ?PaymentsTypes.TxId;
            locks       : ?[(PaymentsTypes.TxId, PaymentsTypes.Lock)];
            purchases   : ?[(PaymentsTypes.TxId, PaymentsTypes.Purchase)];
            refunds     : ?[(PaymentsTypes.TxId, PaymentsTypes.Refund)];
        }
    ) : async () {
        _Payments.restore(caller, backup);
    };

    public shared ({ caller }) func paymentsLock (
        memo : Nat64,
    ) : async Result.Result<PaymentsTypes.TxId, Text> {
        await _Payments.lock(caller, memo);
    };

    public shared ({ caller }) func paymentsNotify (
        memo        : Nat64,
        blockheight : NNSTypes.BlockHeight,
    ) : async Result.Result<EXT.TokenIndex, Text> {
        await _Payments.notify(caller, blockheight, memo, cid);
    };

    public query func paymentsGetPrice () : async Nat64 {
        _Payments.getPrice();
    };

    public query func paymentsGetAvailable () : async Nat {
        _Payments.available();
    };

    public shared ({ caller }) func paymentsProcessRefunds (
        transactions : [PaymentsTypes.NNSTransaction],
    ) : async Result.Result<(), Text> {
        await _Payments.processRefunds(caller, cid, transactions);
    };


    //////////////
    // Payouts //
    ////////////


    // let _Payouts = Payouts.Factory({
    //     admins;
    //     tokens;
    //     nns;
    //     payments;
    // });

    // public shared ({ caller }) func payout () : async PayoutTypes.Manifest {
    //     await payouts.payout(caller, _canisterPrincipal());
    // };


    ///////////
    // HTTP //
    /////////


    let _HttpHandler = Http.HttpHandler({
        _Assets;
        _Admins;
        _Entrepot;
        _Tokens;
        _Payments;
        supply = canisterMeta.supply;
        nri;
    });

    public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
        _HttpHandler.request(request);
    };

};
