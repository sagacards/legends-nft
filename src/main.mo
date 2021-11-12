// 3rd Party Imports

import Array "mo:base/Array";
import Result "mo:base/Result";

// Project Imports

import Admins "Admins";
import Assets "Assets";
import AssetTypes "Assets/types";
import Http "Http";
import HttpTypes "Http/types";
import Ledger "Ledger";
import LedgerTypes "Ledger/types";


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

    private stable var stableLedger : [?Principal] = Array.tabulate<?Principal>(supply, func (i) { null });
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
        assets.purgeAssets(caller, confirm);
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

    public shared func readLedger () : async [?Principal] {
        ledger.read();
    };

    public shared ({ caller }) func mint (
        to : Principal,
    ) : async Result.Result<(), Text> {
        ledger.mint(caller, to);
    };

    public shared ({ caller }) func configureLegends (
        conf : [LedgerTypes.Legend],
    ) : async Result.Result<(), Text> {
        ledger.configureLegends(caller, conf);
    };


    ///////////
    // HTTP //
    /////////


    let httpHandler = Http.HttpHandler({
        assets;
        admins;
        ledger;
    });

    public query func http_request(request : HttpTypes.Request) : async HttpTypes.Response {
        httpHandler.request(request);
    };


};
