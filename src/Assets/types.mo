import Result "mo:base/Result";

import Admins "../Admins";


module Assets {

    public type Tag = Text;
    
    public type FilePath = Text;

    public type State = {
        assets  : [Record];
        colors  : [Color];
        stockColors : [Color];
    };

    public type Dependencies = {
        _Admins : Admins.Admins;
    };

    public type Params = State and Dependencies;

    public type Asset = {
        contentType : Text;
        payload     : [Blob];
    };

    public type Record = {
        asset   : Asset;
        meta    : Meta;
    };

    public type Meta = {
        tags        : [Tag];
        filename    : FilePath;
        name        : Text;
        description : Text;
    };

    public type AssetManifest = [{}];

    public type LegendManifest = {
        back    : Tag;
        border  : Tag;
        ink     : Tag;
        mask    : Tag;
        stock   : Tag;
        nri     : {
            back        : Float;
            border      : Float;
            ink         : Float;
            avg         : Float;
        };
        maps    : {
            normal      : FilePath;
            layers      : [FilePath];
            back        : FilePath;
            border      : FilePath;
            mask        : ?FilePath;
        };
        colors  : {
            base        : Text;
            specular    : Text;
            emissive    : Text;
            background  : Text;
        };
        stockColors: {
            base        : Text;
            specular    : Text;
            emissive    : Text;
        };
        views   : {
            flat        : FilePath;
            sideBySide  : FilePath;
            animated    : FilePath;
            interactive : FilePath;
        }
    };

    // TODO: Use arbitrary traits for colors, backs, etc.
    public type Color = {
        name        : Text;
        base        : Text;
        specular    : Text;
        emissive    : Text;
        background  : Text;
    };

    public type Interface = {
        /// Turns a list of blobs into one blob.
        _flattenPayload : (payload : [Blob]) -> Blob;
        
        /// Finds the first asset with a given tag.
        _findTag : (tag : Text) -> ?Record;

        /// Finds the first asset with all given tag.
        _findTags : (tags : [Text]) -> ?Record;

        /// Finds all assets with a given tag.
        _findAllTag : (tag : Text) -> [Record];

        /// Returns all possible card borders.
        _getAllCardBorders : () -> [Record];

        /// Returns all possible card backs.
        _getAllCardBacks : () -> [Record];

        /// Returns a card preview.
        _getPreview : () -> ?Record;

        /// Retrieve an asset by the given filename.
        getAssetByName : (filename : Text) -> ?Record;

        /// Retrieves the asset manifest (all assets).
        getManifest : () -> [Record];

        /// Upload bytes into the buffer.
        /// @auth: admin
        upload : (caller : Principal, bytes : [Blob]) -> ();

        /// Finalizes the upload buffer into an asset.
        /// @auth: admin
        uploadFinalize : (caller : Principal, contentType : Text, meta : Meta) -> Result.Result<(), Text>;

        /// Clears the upload buffer.
        /// @auth: admin
        uploadClear : (caller : Principal) -> ();

        /// Purges all assets from the canister.
        /// {confirm} needs to be "DELETE ALL ASSETS".
        /// @auth: admin
        purge : (caller : Principal, confirm : Text, tag : ?Text) -> Result.Result<(), Text>;
    };

}