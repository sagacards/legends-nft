import Ext "mo:ext/Ext";
import Time "mo:base/Time";

module {

    public type State = {
        supply : Nat;
    };

    public type Listing = {
        locked: ?Time.Time;
        price: Nat64;
        seller: Principal;
    };

    public type Metadata = {
        #fungible : {
            decimals : Nat8;
            metadata : ?Blob;
            name : Text;
            symbol : Text;
        };
        #nonfungible : {
            metadata : ?Blob;
        };
    };

    public type ListingsResponse = [(
        Ext.TokenIndex,
        Listing,
        Metadata,
    )];

};