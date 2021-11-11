// 3rd Party Imports

import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat32 "mo:base/Nat32";
import Text "mo:base/Text";

// Project Imports

import AssetTypes "../Assets/types";
import Stoic "../Integrations/Stoic";

// Module Imports

import Types "types";


import Debug "mo:base/Debug";


module {

    public class HttpHandler (state : Types.State) {


        ////////////////////
        // Path Handlers //
        //////////////////


        private func path_handler_1 (path : ?Text) : Types.Response {
            {
                body = Text.encodeUtf8("OK");
                headers = [
                    ("Content-Type", "text/plain"),
                ];
                status_code = 200;
                streaming_strategy = null;
            };
        };

        private func path_handler_2 (path : ?Text) : Types.Response {
            {
                body = Text.encodeUtf8("OK");
                headers = [
                    ("Content-Type", "text/plain"),
                ];
                status_code = 200;
                streaming_strategy = null;
            };
        };

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
                    ("Content-Type", "text/plain"),
                ];
                status_code = 200;
                streaming_strategy = null;
            }
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


        public func http_token_preview(request : Types.Request) : Types.Response {
            Debug.print("Token Preview...");
            let tokenId = Iter.toArray(Text.tokens(request.url, #text("tokenid=")))[1];
            let { index } = Stoic.decodeToken(tokenId);
            let legend = state.ledger._getLegend(Nat32.toNat(index));
            Debug.print(legend.back);
            Debug.print(legend.border);
            switch (state.assets._findTags(["static-preview", legend.border])) {
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
            ("path1", path_handler_1),
            ("path2", path_handler_2),
            ("asset", asset_filename_handler),
            ("assets", asset_filename_handler),
            ("asset-manifest", asset_manifest_handler),
        ];


        /////////////////////
        // Request Router //
        ///////////////////


        // This method is magically built into every canister on the IC
        // The request/response types used here are manually configured to mirror how that method works.
        public func request(request : Types.Request) : Types.Response {
            
            // Stoic wallet preview

            if (Text.contains(request.url, #text("tokenid"))) {
                return http_token_preview(request);
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
