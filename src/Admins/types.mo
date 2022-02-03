module Admins {

    public type State = {
        admins  : [Principal];
    };

    public type Interface = {
        // Use this to add an admin-only restriction.
        // @modifier
        _isAdmin : (p : Principal) -> Bool;

        /// Adds a new principal as an admin.
        addAdmin : (caller : Principal, p : Principal) -> ();

        /// Removes the given principal from the list of admins.
        removeAdmin : (caller : Principal, p : Principal) -> ();
        
        // Checks whether the given principal is an admin.
        isAdmin : (caller : Principal, p : Principal) -> Bool;
    };

};