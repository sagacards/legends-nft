import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Error "mo:base/Error";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat16 "mo:base/Nat16";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import AccountIdentifier "mo:principal/AccountIdentifier";
import Canistergeek "mo:canistergeek/canistergeek";
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
import Payouts "Payouts";
import PayoutsTypes "Payouts/types";
import PublicSale "PublicSale";
import PublicSaleTypes "PublicSale/types";
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
    private stable var stableColors : [AssetTypes.Color] = [];

    // Admins

    private stable var stableAdmins : [Principal] = [creator];

    // Tokens

    private stable var stableTokens : [?TokenTypes.Token] = Array.tabulate<?TokenTypes.Token>(Nat16.toNat(canisterMeta.supply), func (i) { null });
    private stable var stableLegends: [TokenTypes.Metadata] = [];
    private stable var stableShuffled = false;

    // Entrepot

    private stable var stableListings               : [(EXT.TokenIndex, EntrepotTypes.Listing)] = [];
    private stable var stableTransactions           : [(Nat, EntrepotTypes.Transaction)] = [];
    private stable var stablePendingTransactions    : [(EXT.TokenIndex, EntrepotTypes.Transaction)] = [];
    private stable var stableUsedPaymentAddress     : [(EXT.AccountIdentifier, Principal, EXT.SubAccount)] = [];
    private stable var stableTotalVolume            : Nat64 = 0;
    private stable var stableLowestPriceSale        : Nat64 = 0;
    private stable var stableHighestPriceSale       : Nat64 = 0;
    private stable var stableEntrepotNextSubAccount : Nat = 0;
    private stable var stablePendingDisbursements   : [(EXT.TokenIndex, EXT.AccountIdentifier, EXT.SubAccount, Nat64)] = [];

    // Public Sale

    private stable var stablePaymentsLocks      : [(PublicSaleTypes.TxId, PublicSaleTypes.Lock)] = [];
    private stable var stablePaymentsPurchases  : [(PublicSaleTypes.TxId, PublicSaleTypes.Purchase)] = [];
    private stable var stablePaymentsNextTxId   : PublicSaleTypes.TxId = 0;
    private stable var stablePaymentsRefunds    : [(PublicSaleTypes.TxId, PublicSaleTypes.Refund)] = [];

    private stable var stablePricePrivateE8s : Nat64 = 200_000_000;
    private stable var stablePricePublicE8s : Nat64 = 200_000_000;

    private stable var presale = true;
    private stable var stableAllowlist          : [(PublicSaleTypes.AccountIdentifier, Nat8)] = [];

    // Canister geek

    private stable var _canistergeekMonitorUD: ? Canistergeek.UpgradeData = null;
    private stable var _canistergeekLoggerUD: ? Canistergeek.LoggerUpgradeData = null;

    // Heartbeat

    private stable var s_heartbeatIntervalSeconds : Nat = 5;
    private stable var s_heartbeatLastBeat : Int = 0;
    private stable var s_heartbeatOn : Bool = true;

    // Upgrades

    system func preupgrade() {

        // Preserve assets
        let { colors; assets } = _Assets.backup();
        stableAssets := assets;
        stableColors := colors;

        // Preserve admins
        stableAdmins := _Admins.toStable();

        // Preserve token ledger
        let { tokens = x; metadata = y; isShuffled } = _Tokens.toStable();
        stableTokens := x;

        // If supply has increased, update stable tokens array
        if (x.size() < Nat16.toNat(canisterMeta.supply)) {
            stableTokens := Array.tabulate<?TokenTypes.Token>(Nat16.toNat(canisterMeta.supply), func (i) {
                switch (i < x.size()) {
                    case (true) x[i];
                    case (false) null;
                }
            });
        };

        // Preserve token metadata
        stableLegends := y;
        stableShuffled := isShuffled;

        // Preserve entrepot
        let {
            listings;
            transactions;
            pendingTransactions;
            _usedPaymentAddresses;
            totalVolume;
            lowestPriceSale;
            highestPriceSale;
            nextSubAccount;
            pendingDisbursements;
        } = _Entrepot.toStable();
        stableListings              := listings;
        stableTransactions          := transactions;
        stablePendingTransactions   := pendingTransactions;
        stableUsedPaymentAddress    := _usedPaymentAddresses;
        stableTotalVolume           := totalVolume;
        stableLowestPriceSale       := lowestPriceSale;
        stableHighestPriceSale      := highestPriceSale;
        stableEntrepotNextSubAccount:= nextSubAccount;
        stablePendingDisbursements  := pendingDisbursements;

        // Preserve Public Sale
        let {
            locks;
            purchases;
            nextTxId;
            refunds;
            allowlist;
            pricePrivateE8s;
            pricePublicE8s;
        } = _PublicSale.toStable();
        stablePaymentsLocks     := locks;
        stablePaymentsPurchases := purchases;
        stablePaymentsRefunds   := refunds;
        stableAllowlist         := allowlist;
        stablePaymentsNextTxId  := nextTxId;
        stablePricePrivateE8s   := pricePrivateE8s;
        stablePricePublicE8s    := pricePublicE8s;
        presale := _PublicSale.presale;

        // Preserve canistergeek

        _canistergeekMonitorUD := ? canistergeekMonitor.preupgrade();
        _canistergeekLoggerUD := ? canistergeekLogger.preupgrade();
    };

    system func postupgrade() {

        canistergeekMonitor.postupgrade(_canistergeekMonitorUD);
        _canistergeekMonitorUD := null;

        canistergeekLogger.postupgrade(_canistergeekLoggerUD);
        _canistergeekLoggerUD := null;
    };


    ////////////////
    // Heartbeat //
    //////////////


    system func heartbeat() : async () {
        if (not s_heartbeatOn) return;

        // Limit heartbeats
        let now = Time.now();
        if (now - s_heartbeatLastBeat < s_heartbeatIntervalSeconds) return;
        s_heartbeatLastBeat := now;
        
        // Run jobs
        await _Entrepot.cronDisbursements();
        await _Entrepot.cronSettlements();
    };

    public shared ({ caller }) func heartbeatSetInterval (
        i : Nat
    ) : async () {
        assert(_Admins._isAdmin(caller));
        s_heartbeatIntervalSeconds := i;
    };

    public shared ({ caller }) func heartbeatSwitch (
        on : Bool
    ) : async () {
        assert(_Admins._isAdmin(caller));
        s_heartbeatOn := on;
    };

    ///////////////////
    // Canistergeek //
    /////////////////


    // Metrics

    private let canistergeekMonitor = Canistergeek.Monitor();

    /**
    * Returns collected data based on passed parameters.
    * Called from browser.
    */
    public query ({caller}) func getCanisterMetrics(parameters: Canistergeek.GetMetricsParameters): async ?Canistergeek.CanisterMetrics {
        assert(_Admins._isAdmin(caller));
        canistergeekMonitor.getMetrics(parameters);
    };

    /**
    * Force collecting the data at current time.
    * Called from browser or any canister "update" method.
    */
    public shared ({caller}) func collectCanisterMetrics(): async () {
        _captureMetrics();
        assert(_Admins._isAdmin(caller));
        canistergeekMonitor.collectMetrics();
    };

    // This needs to be places in every update call.
    private func _captureMetrics () : () {
        canistergeekMonitor.collectMetrics();
    };

    // Logging

    private let canistergeekLogger = Canistergeek.Logger();

    /**
    * Returns collected log messages based on passed parameters.
    * Called from browser.
    */
    public query ({caller}) func getCanisterLog(request: ?Canistergeek.CanisterLogRequest) : async ?Canistergeek.CanisterLogResponse {
        assert(_Admins._isAdmin(caller));
        canistergeekLogger.getLog(request);
    };

    private func _log (
        caller  : Principal,
        method  : Text,
        message : Text,
    ) : () {
        canistergeekLogger.logMessage(
            Principal.toText(caller) # " :: " #
            method # " :: " #
            message
        );
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
        _captureMetrics();
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
        _captureMetrics();
        assert(_Admins._isAdmin(caller));
        nri := data;
        _HttpHandler.updateNri(data);
    };

    public shared ({ caller }) func addAdmin (
        p : Principal,
    ) : async () {
        _captureMetrics();
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
        _captureMetrics();
        _Admins.removeAdmin(caller, p);
    };

    public query func getAdmins () : async [Principal] {
        _Admins.getAdmins();
    };

    // Allowlist

    public shared ({ caller }) func togglePresale(b : Bool) {
        _captureMetrics();
        assert(_Admins._isAdmin(caller));
        _PublicSale.presale := b;
    };

    public shared ({ caller }) func isPresale () : async Bool {
        _captureMetrics();
        _PublicSale.presale;
    };

    public shared ({ caller }) func setAllowlist(
        allowlist : [(Text, Nat8)],
    ) {
        _captureMetrics();
        assert(_Admins._isAdmin(caller));
        let h = HashMap.HashMap<PublicSaleTypes.AccountIdentifier, Nat8>(
            allowlist.size(),
            AccountIdentifier.equal,
            AccountIdentifier.hash,
        );
        for ((k, v) in Iter.fromArray(allowlist)) h.put(switch (AccountIdentifier.fromText(k)) {
            case (#ok(x)) x;
            case _ throw Error.reject("Invalid account");
        }, v);
        _PublicSale.allowlist := h;
    };

    public query ({ caller }) func getAllowlist() : async [(PublicSaleTypes.AccountIdentifier, Nat8)] {
        assert(_Admins._isAdmin(caller));
        Iter.toArray(_PublicSale.allowlist.entries());
    };
    
    
    /////////////
    // Assets //
    ///////////


    let _Assets = Assets.Assets({
        _Admins;
        assets = stableAssets;
        colors = stableColors;
    });

    public shared ({ caller }) func upload (
        bytes : [Blob],
    ) : async () {
        _captureMetrics();
        _Assets.upload(caller, bytes);
    };

    public shared ({ caller }) func uploadFinalize (
        contentType : Text,
        meta        : AssetTypes.Meta,
    ) : async Result.Result<(), Text> {
        _captureMetrics();
        _Assets.uploadFinalize(
            caller,
            contentType,
            meta,
        );
    };

    public shared ({ caller }) func uploadClear () : async () {
        _captureMetrics();
        _Assets.uploadClear(caller);
    };

    public shared ({ caller }) func purgeAssets (
        confirm : Text,
        tag     : ?Text,
    ) : async Result.Result<(), Text> {
        _captureMetrics();
        _Assets.purge(caller, confirm, tag);
    };

    public query ({ caller }) func assetsBackup () : async AssetTypes.State {
        assert _Admins._isAdmin(caller);
        _Assets.backup();
    };

    public query ({ caller }) func assetsRestore (
        backup : AssetTypes.State
    ) : async () {
        assert _Admins._isAdmin(caller);
        _Assets.restore(backup);
    };

    public shared ({ caller }) func assetsTag (
        files : [(
            file    : Text,
            tags    : [Text],
        )],
    ) : async () {
        _captureMetrics();
        _Assets.tag(caller, files);
    };

    public shared ({ caller }) func configureColors (
        colors : [AssetTypes.Color],
    ) : async () {
        _captureMetrics();
        _Assets.configureColors(caller, colors);
    };


    /////////////
    // Tokens //
    ///////////


    let _Tokens = Tokens.Factory({
        _Admins;
        _Assets;
        _Cap;
        tokens      = stableTokens;
        metadata    = stableLegends;
        isShuffled  = stableShuffled;
        supply      = canisterMeta.supply;
        cid;
    });

    public shared func readLedger () : async [?TokenTypes.Token] {
        _captureMetrics();
        _Tokens.read(null);
    };

    public shared ({ caller }) func mint (
        to : EXT.User,
    ) : async Result.Result<Nat, Text> {
        _captureMetrics();
        await _Tokens.mint(caller, to);
    };

    public shared ({ caller }) func configureMetadata (
        conf : [TokenTypes.Metadata],
    ) : async Result.Result<(), Text> {
        _captureMetrics();
        _Tokens.configureMetadata(caller, conf);
    };

    public query ({ caller }) func tokensBackup () : async TokenTypes.LocalStableState {
        _Tokens.backup(caller);
    };

    public shared ({ caller }) func tokensRestore (
        backup : TokenTypes.LocalStableState,
    ) : async Result.Result<(), Text> {
        _captureMetrics();
        _Tokens.restore(caller, backup);
    };

    public shared ({ caller }) func shuffleMetadata () : async () {
        _captureMetrics();
        await _Tokens.shuffleMetadata(caller);
    };

    public query func readMeta () : async [TokenTypes.Metadata] {
        _Tokens.readMeta();
    };

    public query func getTokens() : async [(EXT.TokenIndex, EXT.Common.Metadata)] {
        _Tokens.getTokens();
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
        _captureMetrics();
        await _Nns.balance(NNS.accountIdentifier(cid, NNS.defaultSubaccount()));
    };

    public shared ({ caller }) func nnsTransfer (
        amount  : NNSTypes.ICP,
        to      : Text,
        memo    : NNSTypes.Memo,
    ) : async NNSTypes.TransferResult {
        _captureMetrics();
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
        cid;
        listings            = stableListings;
        transactions        = stableTransactions;
        pendingTransactions = stablePendingTransactions;
        supply              = canisterMeta.supply;
        _usedPaymentAddresses = stableUsedPaymentAddress;
        totalVolume         = stableTotalVolume;
        lowestPriceSale     = stableLowestPriceSale;
        highestPriceSale    = stableHighestPriceSale;
        nextSubAccount      = stableEntrepotNextSubAccount;
        pendingDisbursements= stablePendingDisbursements;
        _log;
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
        _captureMetrics();
        _log(caller, "list", request.token # " :: Start");
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
        _captureMetrics();
        _log(caller, "lock", token # " :: Start");
        await _Entrepot.lock(caller, token, price, buyer, bytes);
    };

    public shared ({ caller }) func settle (
        token : EXT.TokenIdentifier,
    ) : async Result.Result<(), EXT.CommonError> {
        _captureMetrics();
        _log(caller, "settle", token # " :: Start");
        await _Entrepot.settle(caller, token);
    };

    public query ({ caller }) func payments () : async ?[EXT.SubAccount] {
        _Entrepot.payments(caller);
    };

    public query ({ caller }) func paymentsRaw () : async [(Nat, EntrepotTypes.Transaction)] {
        _Entrepot.paymentsRaw(caller);
    };

    public query ({ caller }) func readPending () : async [(EXT.TokenIndex, EntrepotTypes.Transaction)] {
        _Entrepot.readPending(caller);
    };

    public query ({ caller }) func transactions () : async [EntrepotTypes.EntrepotTransaction] {
        _Entrepot.readTransactions();
    };

    public shared ({ caller }) func entrepotRestore (
        backup : EntrepotTypes.Backup
    ) : async () {
        _captureMetrics();
        _Entrepot.restore(caller, backup);
    };

    public shared ({ caller }) func deleteListing (
        index : EXT.TokenIndex,
    ) : async () {
        _Entrepot.deleteListing(caller, index);
    };


    //////////
    // EXT //
    ////////


    let _Ext = Ext.make({
        _Entrepot;
        _Tokens;
        _Cap;
        cid;
    });

    public shared ({ caller }) func allowance(
        request : EXT.Allowance.Request,
    ) : async EXT.Allowance.Response {
        _captureMetrics();
        _Ext.allowance(caller, request);
    };

    public query func bearer(
        tokenId : EXT.TokenIdentifier,
    ) : async EXT.NonFungible.BearerResponse {
        _Ext.bearer(tokenId);
    };
    
    public query ({ caller }) func metadata(
        tokenId : EXT.TokenIdentifier,
    ) : async EXT.Common.MetadataResponse {
        _Ext.metadata(caller, tokenId);
    };

    public shared ({ caller }) func approve(
        request : EXT.Allowance.ApproveRequest,
    ) : async () {
        _captureMetrics();
        _Ext.approve(caller, request);
    };

    public shared ({ caller }) func transfer(
        request : EXT.Core.TransferRequest,
    ) : async EXT.Core.TransferResponse {
        _captureMetrics();
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

    public query func getRegistry() : async [(EXT.TokenIndex, EXT.AccountIdentifier)] {
        _Ext.getRegistry();
    };


    //////////////////
    // Public Sale //
    ////////////////


    let _PublicSale = PublicSale.Factory({
        _Admins;
        _Cap;
        _Nns;
        _Tokens;
        locks       = stablePaymentsLocks;
        purchases   = stablePaymentsPurchases;
        refunds     = stablePaymentsRefunds;
        allowlist   = stableAllowlist;
        nextTxId    = stablePaymentsNextTxId;
        pricePrivateE8s = stablePricePrivateE8s;
        pricePublicE8s = stablePricePublicE8s;
        cid;
        presale;
    });
    _PublicSale.presale := presale;

    public query func publicSaleBackup () : async {
        nextTxId    : PublicSaleTypes.TxId;
        locks       : [(PublicSaleTypes.TxId, PublicSaleTypes.Lock)];
        purchases   : [(PublicSaleTypes.TxId, PublicSaleTypes.Purchase)];
        refunds     : [(PublicSaleTypes.TxId, PublicSaleTypes.Refund)];
        allowlist   : [(PublicSaleTypes.AccountIdentifier, Nat8)];
    } {
        _PublicSale.toStable();
    };

    public shared ({ caller }) func publicSaleRestore (
        backup : {
            nextTxId    : ?PublicSaleTypes.TxId;
            locks       : ?[(PublicSaleTypes.TxId, PublicSaleTypes.Lock)];
            purchases   : ?[(PublicSaleTypes.TxId, PublicSaleTypes.Purchase)];
            refunds     : ?[(PublicSaleTypes.TxId, PublicSaleTypes.Refund)];
            allowlist   : ?[(PublicSaleTypes.AccountIdentifier, Nat8)];
            presale     : ?Bool;
            pricePrivateE8s : ?Nat64;
            pricePublicE8s : ?Nat64;
        }
    ) : async () {
        _captureMetrics();
        _PublicSale.restore(caller, backup);
    };

    public shared ({ caller }) func publicSaleLock (
        memo : Nat64,
    ) : async Result.Result<PublicSaleTypes.TxId, Text> {
        _captureMetrics();
        await _PublicSale.lock(caller, memo);
    };

    public shared ({ caller }) func publicSaleNotify (
        memo        : Nat64,
        blockheight : NNSTypes.BlockHeight,
    ) : async Result.Result<EXT.TokenIndex, Text> {
        _captureMetrics();
        await _PublicSale.notify(caller, blockheight, memo, cid);
    };

    public query func publicSaleGetPrice () : async Nat64 {
        _PublicSale.getPrice();
    };

    public query func publicSaleGetAvailable () : async Nat {
        _PublicSale.available();
    };

    public shared ({ caller }) func publicSaleProcessRefunds (
        transactions : [PublicSaleTypes.NNSTransaction],
    ) : async Result.Result<(), Text> {
        _captureMetrics();
        await _PublicSale.processRefunds(caller, cid, transactions);
    };

    public shared ({ caller }) func configurePublicSalePrice (
        privatePriceE8s : Nat64,
        publicPriceE8s : Nat64,
    ) : async () {
        _captureMetrics();
        _PublicSale.configurePrice(caller, privatePriceE8s, publicPriceE8s);
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
        _PublicSale;
        supply = canisterMeta.supply;
        nri;
        cid;
    });

    public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
        _HttpHandler.request(request);
    };

};
