// 3rd Party Imports

import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Ext "mo:ext/Ext";

// Project Imports

import Admins "Admins";
import Assets "Assets";
import AssetTypes "Assets/types";
import Http "Http";
import HttpTypes "Http/types";
import Ledger "Ledger";
import LedgerTypes "Ledger/types";
import Entrepot "Entrepot";
import EntrepotTypes "Entrepot/types";
import ExtFactory "Ext";
import ExtTypes "Ext/types";


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

    // Upgrades

    system func preupgrade() {

        // Preserve assets
        stableAssets := assets.toStable();

        // Preserve admins
        stableAdmins := admins.toStable();

        let { ledger = x; legends } = ledger.toStable();

        // Preserve ledger
        stableLedger := x;

        // Preserve legends
        stableLegends := legends;
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

    public query ({ caller }) func details(
        tokenId : Ext.TokenIdentifier
    ) : async Result.Result<(Ext.AccountIdentifier, ?ExtTypes.Listing), Ext.CommonError> {
        ext.details(caller, tokenId);
    };

    public query func tokenId(
        index : Ext.TokenIndex,
    ) : async Ext.TokenIdentifier {
        ext.tokenId(_canisterPrincipal(), index);
    };


    ///////////////
    // Entrepot //
    /////////////

    let entrepot = Entrepot.Factory({ supply; });

    public query func listings () : async EntrepotTypes.ListingsResponse {
        entrepot.getListings();
    };

};
