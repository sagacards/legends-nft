// 3rd Party Imports

import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";

// Project Imports

import AssetTypes "../Assets/types";
import Stoic "../Integrations/Stoic";

// Module Imports

import Types "types";


module {

    public class HttpHandler (state : Types.State) {


        ////////////////////
        // Path Handlers //
        //////////////////


        // Serves an asset based on its filename.
        private func asset_filename_handler (path : ?Text) : Types.Response {
            switch (path) {
                case (?path) {
                    switch (state.assets.getAssetByName(path)) {
                        case (?asset) ({
                            body = state.assets._flattenPayload(asset.asset.payload);
                            headers = [
                                ("Content-Type", "text/plain"),
                            ];
                            status_code = 200;
                            streaming_strategy = null;
                        });
                        case _ http_404(?"Asset not found.");
                    };
                };
                case _ return asset_manifest_handler(path);
            };
        };

        // Serves a JSON list of all assets in the canister.
        private func asset_manifest_handler (path : ?Text) : Types.Response {
            {
                body = Text.encodeUtf8(
                    "[\n" #
                    Array.foldLeft<AssetTypes.Record, Text>(state.assets.getManifest(), "", func (a, b) {
                        let comma = switch (a == "") {
                            case true "\t";
                            case false ", ";
                        };
                        a # comma # "{\n" #
                            "\t\t\"filename\": \"" # b.meta.filename # "\",\n" #
                            "\t\t\"url\": \"/assets/" # b.meta.filename # "\",\n" #
                            "\t\t\"description\": \"" # b.meta.description # "\",\n" #
                            "\t\t\"tags\": [" # Array.foldLeft<Text, Text>(b.meta.tags, "", func (a, b) {
                                let comma = switch (a == "") {
                                    case true "";
                                    case false ", ";
                                };
                                a # comma # "\"" # b # "\""
                            }) # "]\n" #
                        "\t}";
                    }) #
                    "\n]"
                );
                headers = [
                    ("Content-Type", "application/json"),
                ];
                status_code = 200;
                streaming_strategy = null;
            }
        };

        // Serves a JSON manifest of all assets required to render a particular legend
        private func legend_manifest_handler (path : ?Text) : Types.Response {
            let index : ?Nat = switch (path) {
                case (?path) {
                    var match : ?Nat = null;
                    for (i in Iter.range(0, state.supply - 1)) {
                        if (Nat.toText(i) == path) {
                            match := ?i;
                        };
                    };
                    match;
                };
                case _ null;
            };
            switch (index) {
                case (?i) {
                    let { back; border; ink; } = state.ledger.nfts(?i)[0];
                    let manifest : AssetTypes.LegendManifest = {
                        back;
                        border;
                        ink;
                        maps = {
                            normal = do {
                                switch (state.assets._findTag("normal")) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                            layers = do {
                                Array.map<AssetTypes.Record, AssetTypes.FilePath>(
                                    state.assets._findAllTag("layer"),
                                    func (record) {
                                        record.meta.filename;
                                    },
                                );
                            };
                            back = do {
                                switch (state.assets._findTags(["back", back])) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                            border = do {
                                switch (state.assets._findTags(["border", border])) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                            background = do {
                                switch (state.assets._findTag("background")) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                        };
                        colors = do {
                            var map = {
                                base     = "#000000";
                                specular = "#000000";
                                emissive = "#000000";
                            };
                            for ((name, colors) in state.assets.inkColors.vals()) {
                                if (name == ink) map := colors;
                            };
                            map;
                        };
                        views = {
                            flat = do {
                                switch (state.assets._findTags(["preview", "flat"])) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                            sideBySide = do {
                                switch (state.assets._findTags(["preview", "side-by-side"])) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                            animated = do {
                                switch (state.assets._findTags(["preview", "animated"])) {
                                    case (?a) a.meta.filename;
                                    case _ "";
                                };
                            };
                            interactive = "";
                        };
                    };
                    return {
                        body = Text.encodeUtf8("{\n" #
                            "\t\"back\"     : \"" # manifest.back # "\",\n" #
                            "\t\"border\"   : \"" # manifest.border # "\",\n" #
                            "\t\"ink\"      : \"" # manifest.ink # "\",\n" #
                            "\t\"maps\"     : {\n" #
                                "\t\t\"normal\"     : \"/assets/" # manifest.maps.normal # "\",\n" #
                                "\t\t\"back\"       : \"/assets/" # manifest.maps.back # "\",\n" #
                                "\t\t\"border\"     : \"/assets/" # manifest.maps.border # "\",\n" #
                                "\t\t\"background\" : \"/assets/" # manifest.maps.background # "\",\n" #
                                "\t\t\"layers\"     : [\n" #
                                    Array.foldLeft<AssetTypes.FilePath, Text>(
                                        manifest.maps.layers,
                                        "",
                                        func (a, b) {
                                            let comma = switch (a == "") {
                                                case true "\t\t\t";
                                                case false ",\n\t\t\t";
                                            };
                                            return a # comma # "\"/assets/" # b # "\""
                                        },
                                    ) # "\n" #
                                "\t\t]\n" #
                            "\t},\n" #
                            "\t\"colors\": {\n" #
                                "\t\t\"base\"       : \"" # manifest.colors.base # "\",\n" #
                                "\t\t\"specular\"   : \"" # manifest.colors.specular # "\",\n" #
                                "\t\t\"emissive\"   : \"" # manifest.colors.emissive # "\"\n" #
                            "\t},\n" #
                            "\t\"views\": {\n" #
                                "\t\t\"flat\"       : \"/assets/" # manifest.views.flat # "\",\n" #
                                "\t\t\"sideBySide\" : \"/assets/" # manifest.views.sideBySide # "\",\n" #
                                "\t\t\"animated\"   : \"/assets/" # manifest.views.animated # "\",\n" #
                                "\t\t\"interactive\": \"" # manifest.views.interactive # "\"\n" #
                            "\t}\n" #
                        "\n}");
                        headers = [
                            ("Content-Type", "application/json"),
                        ];
                        status_code = 200;
                        streaming_strategy = null;
                    };
                };
                case null http_404(?"Invalid index.")
            }
        };

        public func http_token_index_preview (request : Types.Request) : Types.Response {
            let index = Iter.toArray(Text.tokens(request.url, #text("tokenindex=")))[1];
            var j : ?Nat = null;
            label l for (i in Iter.range(0, state.supply)) {
                if (Nat.toText(i) == index) {
                    j := ?i;
                    break l;
                };
            };
            switch (j) {
                case (?j) {
                    let legend = state.ledger._getLegend(j);
                    switch (
                        state.assets._findTags([
                            "preview", "side-by-side", "back-" # legend.back,
                            "border-" # legend.border, "ink-" # legend.ink
                        ])
                    ) {
                        case (?asset) ({
                            body = state.assets._flattenPayload(asset.asset.payload);
                            headers = [
                                ("Content-Type", "text/plain"),
                                ("Cache-Control", "max-age=31536000"), // Cache one year
                            ];
                            status_code = 200;
                            streaming_strategy = null;
                        });
                        case null http_404(?"Missing preview asset.");
                    };
                };
                case _ http_404(?"No token at that index.");
            };
        };
        
        
        //////////////////////////////////////
        // Generic Handlers                 //
        //////////////////////////////////////


        private func index_handler () : Types.Response {
            {
                body = "Pong!";
                headers = [
                    ("Content-Type", "text/plain"),
                ];
                status_code = 200;
                streaming_strategy = null;
            };
        };


        private func http_404(msg : ?Text) : Types.Response {
            {
                body = Text.encodeUtf8(
                    switch (msg) {
                        case (?msg) msg;
                        case null "Not found.";
                    }
                );
                headers = [
                    ("Content-Type", "text/plain"),
                ];
                status_code = 404;
                streaming_strategy = null;
            };
        };

        private func http_400(msg : ?Text) : Types.Response {
            {
                body = Text.encodeUtf8(
                    switch (msg) {
                        case (?msg) msg;
                        case null "Bad request.";
                    }
                );
                headers = [
                    ("Content-Type", "text/plain"),
                ];
                status_code = 400;
                streaming_strategy = null;
            };
        };


        /////////////////////
        // Stoic Handlers //
        ///////////////////


        public func http_stoic_token_preview(request : Types.Request) : Types.Response {
            let tokenId = Iter.toArray(Text.tokens(request.url, #text("tokenid=")))[1];
            let { index } = Stoic.decodeToken(tokenId);
            let legend = state.ledger._getLegend(Nat32.toNat(index));
            switch (
                state.assets._findTags([
                    "preview", "side-by-side", "back-" # legend.back,
                    "border-" # legend.border, "ink-" # legend.ink
                ])
            ) {
                case (?asset) ({
                    body = state.assets._flattenPayload(asset.asset.payload);
                    headers = [
                        ("Content-Type", "text/plain"),
                        ("Cache-Control", "max-age=31536000"), // Cache one year
                    ];
                    status_code = 200;
                    streaming_strategy = null;
                });
                case null http_404(?"Missing preview asset.");
            };
        };


        //////////////////
        // Path Config //
        ////////////////


        let paths : [(Text, (path: ?Text) -> Types.Response)] = [
            ("asset", asset_filename_handler),
            ("assets", asset_filename_handler),
            ("asset-manifest", asset_manifest_handler),
            ("legend-manifest", legend_manifest_handler),
        ];


        /////////////////////
        // Request Router //
        ///////////////////


        // This method is magically built into every canister on the IC
        // The request/response types used here are manually configured to mirror how that method works.
        public func request(request : Types.Request) : Types.Response {
            
            // Stoic wallet preview

            if (Text.contains(request.url, #text("tokenid"))) {
                return http_stoic_token_preview(request);
            };

            if (Text.contains(request.url, #text("tokenindex"))) {
                return http_token_index_preview(request);
            };

            // Paths

            let path = Iter.toArray(Text.tokens(request.url, #text("/")));

            switch (path.size()) {
                case 0 return index_handler();
                case 1 for ((key, handler) in Iter.fromArray(paths)) {
                    if (path[0] == key) return handler(null);
                };
                case 2 for ((key, handler) in Iter.fromArray(paths)) {
                    if (path[0] == key) return handler(?path[1]);
                };
                case _ for ((key, handler) in Iter.fromArray(paths)) {
                    if (path[0] == key) return handler(?path[1]);
                };
            };
            
            for ((key, handler) in Iter.fromArray(paths)) {
                if (path[0] == key) return handler(?path[1])
            };

            // 404

            return http_404(?"Path not found.");
        };
    };
};
