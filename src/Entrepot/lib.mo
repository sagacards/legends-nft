import Array "mo:base/Array";

import Types "types"

module {

    public class Factory (state : Types.State) {

        ////////////
        // State //
        //////////


        let listings : [var Bool] = Array.init<Bool>(state.supply, false);


        /////////////////
        // Public API //
        ///////////////


        public func getListings () : Types.ListingsResponse {
            return [];
        };

    };

};