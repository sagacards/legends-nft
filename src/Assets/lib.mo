import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Admins "../Admins";
import Types "types";


module {

    public class Assets (state : Types.State) {


        ////////////////
        // Internals //
        //////////////


        // Writes a new asset to state, including the denormalized index
        private func _addAsset (record : Types.Record) : Result.Result<(), Text> {
            switch (files.get(record.meta.filename)) {
                case (?i) {
                    // Add asset to state
                    assets.put(i, record);
                    #ok();
                };
                case _ {
                    // Store a denormalized index of filename to asset index
                    files.put(record.meta.filename, assets.size());
                    // Add asset to state
                    assets.add(record);
                    #ok();
                };
            };
        };

        // Determine whether an asset has a given tag.
        private func _assetHasTag (
            asset   : Types.Record,
            tag     : Text,
        ) : Bool {
            for (t in asset.meta.tags.vals()) {
                if (t == tag) return true;
            };
            return false;
        };


        ////////////////
        // Utilities //
        //////////////


        // Turn a list of blobs into one blob.
        public func _flattenPayload (payload : [Blob]) : Blob {
            Blob.fromArray(
                Array.foldLeft<Blob, [Nat8]>(payload, [], func (a : [Nat8], b : Blob) {
                    Array.append(a, Blob.toArray(b));
                })
            );
        };

        // Find the first asset with a given tag.
        public func _findTag (tag : Text) : ?Types.Record {
            Array.find<Types.Record>(assets.toArray(), func (asset : Types.Record) {
                _assetHasTag(asset, tag);
            });
        };

        // Find the first asset with all given tag.
        public func _findTags (tags : [Text]) : ?Types.Record {
            Array.find<Types.Record>(assets.toArray(), func (asset : Types.Record) {
                for (tag in tags.vals()) {
                    if (_assetHasTag(asset, tag) == false) return false;
                };
                return true;
            });
        };

        // Find all asset with a given tag.
        public func _findAllTag (tag : Text) : [Types.Record] {
            Array.filter<Types.Record>(assets.toArray(), func (asset : Types.Record) {
                _assetHasTag(asset, tag);
            });
        };

        // Get all possible card borders.
        public func _getAllCardBorders () : [Types.Record] {
            _findAllTag("border");
        };

        // Get all possible card backs.
        public func _getAllCardBacks () : [Types.Record] {
            _findAllTag("backs");
        };

        // Get card preview.
        public func _getPreview () : ?Types.Record {
            _findTag("preview");
        };


        ////////////
        // State //
        //////////

        
        // The upload buffer, for adding additional assets.
        private let buffer : Buffer.Buffer<Blob> = Buffer.Buffer(0);

        // A denormalized hashmap for looking up assets.
        private let files : HashMap.HashMap<Text, Nat> = HashMap.HashMap(0, Text.equal, Text.hash);

        // We store assets in a buffer, where each asset has some metadata and an asset payload.
        // Assets are retrieved from the buffer by searching on their metadata.
        private let assets : Buffer.Buffer<Types.Record> = Buffer.Buffer(0);

        // Provision assets from stable state.
        for (asset in state.assets.vals()) {
            ignore _addAsset(asset);
        };

        public func toStable () : [Types.Record] {
            return assets.toArray();
        };


        ////////////////////////////
        // Ink Color Definitions //
        //////////////////////////


        public let inkColors : [
            (
                Text,
                {
                    base     : Types.Color;
                    specular : Types.Color;
                    emissive : Types.Color;
                }
            )
        ] = [
            ("copper", {
                base     = "#000000";
                specular = "#4e230a";
                emissive = "#a78319";
            }),
            ("silver", {
                base     = "#33343b";
                specular = "#8e98a0";
                emissive = "#c4c0a7";
            }),
            ("gold", {
                base     = "#764007";
                specular = "#c1ab59";
                emissive = "#c1ab59";
            }),
            ("canopy", {
                base     = "#3a3e39";
                specular = "#57b44b";
                emissive = "#424800";
            }),
            ("rose", {
                base     = "#524f32";
                specular = "#4b0000";
                emissive = "#ff00ee";
            }),
            ("spice", {
                base     = "#341414";
                specular = "#620909";
                emissive = "#b40000";
            }),
            ("midnight", {
                base     = "#191224";
                specular = "#7239aa";
                emissive = "#00536c";
            }),
        ];


        /////////////////
        // Public API //
        ///////////////


        // Retrieve an asset.
        public func getAssetByName (
            filename : Text,
        ) : ?Types.Record {
            switch (files.get(filename)) {
                case (?index) ?assets.get(index);
                case _ null;
            };
        };

        // Retrieve the asset manifest.
        public func getManifest () : [Types.Record] {
            assets.toArray();
        };


        ////////////////
        // Admin API //
        //////////////


        // Upload bytes into the buffer.
        // @auth: admin
        public func upload(
            caller  : Principal,
            bytes   : [Blob],
        ) : () {
            assert(state._Admins._isAdmin(caller));
            for (byte in bytes.vals()) {
                buffer.add(byte);
            }
        };

        // Finalize the upload buffer into an asset.
        // @auth: admin
        public func uploadFinalize(
            caller      : Principal,
            contentType : Text,
            meta        : Types.Meta,
        ) : Result.Result<(), Text> {
            assert(state._Admins._isAdmin(caller));
            switch (
                _addAsset({
                    asset = {
                        contentType = contentType;
                        payload = buffer.toArray();
                    };
                    meta;
                })
            ) {
                case (#err(msg)) return #err(msg);
                case _ {
                    buffer.clear();
                    return #ok();
                }
            };
        };

        // Clear the upload buffer
        // @auth: admin
        public func uploadClear(
            caller : Principal,
        ) : () {
            assert(state._Admins._isAdmin(caller));
            buffer.clear();
        };

        // Purge all assets from the canister
        // @auth: admin
        public func purge(
            caller  : Principal,
            confirm : Text,
            tag     : ?Text,
        ) : Result.Result<(), Text> {
            assert(state._Admins._isAdmin(caller));
            if (confirm != "DELETE ALL ASSETS") {
                return #err("Please confirm your intention to delete all assets by typing in \"DELETE ALL ASSETS\"");
            };
            switch (tag) {
                case (?t) {
                    var i = 0;
                    for (asset in assets.vals()) {
                        
                    };
                };
                case _ {
                    assets.clear();
                    for ((key, value) in files.entries()) {
                        files.delete(key);
                    };
                };
            };
            #ok();
        };

    };

};