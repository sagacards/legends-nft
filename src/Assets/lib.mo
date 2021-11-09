// 3rd Party Imports

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import HashMap "mo:base/HashMap";
import Result "mo:base/Result";
import Text "mo:base/Text";

// Project Imports

import Admins "../Admins";

// Module Imports

import Types "types";


module {

    public class Assets (state : Types.State) {


        //////////////////////////////
        // Utilities and Internals //
        ////////////////////////////


        // Writes a new asset to state, including the denormalized index
        private func _addAsset (record : Types.Record) : Result.Result<(), Text> {
            switch (files.get(record.meta.filename)) {
                case (?exists) return #err("Filename already exists.");
                case _ {
                    // Store a denormalized index of filename to asset index
                    files.put(record.meta.filename, assets.size());
                    // Add asset to state
                    assets.add(record);
                    #ok();
                };
            };
        };

        public func flattenPayload (payload : [Blob]) : Blob {
            Blob.fromArray(
                Array.foldLeft<Blob, [Nat8]>(payload, [], func (a : [Nat8], b : Blob) {
                    Array.append(a, Blob.toArray(b));
                })
            );
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


        /////////////////
        // Public API //
        ///////////////


        // Retrieve an asset
        public func getAssetByName (
            filename : Text,
        ) : ?Types.Record {
            switch (files.get(filename)) {
                case (?index) ?assets.get(index);
                case _ null;
            };
        };

        // Retrieve the asset manifest
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
            assert(state.admins._isAdmin(caller));
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
            assert(state.admins._isAdmin(caller));
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
            assert(state.admins._isAdmin(caller));
            buffer.clear();
        };

        // Purge all assets from the canister
        // @auth: admin
        public func purgeAssets(
            caller  : Principal,
            confirm : Text,
        ) : Result.Result<(), Text> {
            if (confirm != "DELETE ALL ASSETS") {
                return #err("Please confirm your intention to delete all assets by typing in \"DELETE ALL ASSETS\"");
            };
            assets.clear();
            for ((key, value) in files.entries()) {
                files.delete(key);
            };
            #ok();
        };

    };

};