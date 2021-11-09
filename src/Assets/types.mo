import Admins "../Admins";


module Assets {

    public type State = {
        assets : [Record];
        admins : Admins.Admins;
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
        tags        : [Text];
        filename    : Text;
        description : Text;
    };

}