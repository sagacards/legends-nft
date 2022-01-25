import Admins "../Admins";


module Assets {

    public type Tag = Text;
    
    public type FilePath = Text;

    public type Color = Text;

    public type State = {
        assets  : [Record];
        _Admins : Admins.Admins;
    };

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
            background   : FilePath;
        };
        colors  : {
            base        : Color;
            specular    : Color;
            emissive    : Color;
        };
        views   : {
            flat        : FilePath;
            sideBySide  : FilePath;
            animated    : FilePath;
            interactive : FilePath;
        }
    };

}