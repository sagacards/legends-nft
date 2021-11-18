// 3rd Party Imports

import Admins "Admins";
import Array "mo:base/Array";
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
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Types "Entrepot/types";


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
        stableListings := listings;
        stableTransactions := transactions;
        stablePendingTransactions := pendingTransactions;

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
        confirm : Text
    ) : async Result.Result<(), Text> {
        assets.purge(caller, confirm);
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

    public query ({ caller }) func backup () : async [?LedgerTypes.Token] {
        ledger.backup(caller);
    };

    public shared ({ caller }) func restore (
        data : [?LedgerTypes.Token],
    ) : async Result.Result<(), Text> {
        ledger.restore(caller, data);
    };


    ///////////
    // HTTP //
    /////////


    let httpHandler = Http.HttpHandler({
        assets;
        admins;
        ledger;
        supply;
    });

    public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
        httpHandler.request(request);
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
    ) : async Types.LockResponse {
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

};
