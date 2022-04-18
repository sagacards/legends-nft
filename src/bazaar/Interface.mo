import Result "mo:base/Result";

import NNSTypes "../NNS/types";

module Interface {
    /// 🛑 Admin restricted functions.
    public type Admin = actor {
        addAdmin : shared (a : Principal) -> ();
        removeAdmin : shared (a : Principal) -> ();
        getAdmins : query () -> async [Principal];
        removeEvent: shared (token : Principal, index : Nat) -> ();
    };

    public type MintResult = Result.Result<Nat, MintError>;

    public type MintError = {
        /// Describes a ledger transfer error.
        #Transfer : TransferError;
        /// Indicates that the mint failed but the paid amount got refunded.
        #Refunded;
        /// Describes an event error;
        #Events : Error;
        /// Indicates that you are not in the allowlist and are not allowed to mint.
        #NoMintingSpot;
        /// Indicates that no more NFTs are available.
        #NoneAvailable;
        /// Indicates that an external services trapped...
        #TryCatchTrap;
    };

    /// 🟢 Public functions.
    public type Account = actor {
        getAllowlistSpots : query (token : Principal, index : Nat) -> async Result.Result<Int, Error>;
        getPersonalAccount : query () -> async AccountIdentifier;
        balance : shared () -> async NNSTypes.ICP;
        transfer : shared (amount : NNSTypes.ICP, to : AccountIdentifier) -> async TransferResult;
        mint : shared (token : Principal, index : Nat) -> async MintResult;
    };

    public type Events = actor {
        /// Creates a new event.
        createEvent : shared (data : Data) -> async Nat;
        /// Updates an existing event.
        updateEvent : shared (index : Nat, data : Data) -> async Result<()>;
        /// Returns a specific event for the given token.
        getEvent : query (token : Principal, index : Nat) -> async Result<Data>;
        /// Returns all events of the {caller}.
        getOwnEvents : query () -> async [Data];
        /// Returns all events.
        getAllEvents : query () -> async [Event];
        /// Returns all events for the given tokens.
        getEvents : query (tokens : [Principal]) -> async [Event];
        /// Returns the events for the given token.
        getEventsOfToken : query (token : Principal) -> async [Data];
    };

    public type Main = Admin and Account and Events;

    public type AccountIdentifier = Blob;

    public type TransferError = {
        // The fee that the caller specified in the transfer request was not the one that ledger expects.
        // The caller can change the transfer fee to the `expected_fee` and retry the request.
        #BadFee : { expected_fee : NNSTypes.ICP; };
        // The account specified by the caller doesn't have enough funds.
        #InsufficientFunds : { balance: NNSTypes.ICP; };
        // The request is too old.
        // The ledger only accepts requests created within 24 hours window.
        // This is a non-recoverable error.
        #TxTooOld : { allowed_window_nanos: Nat64 };
        // The caller specified `created_at_time` that is too far in future.
        // The caller can retry the request later.
        #TxCreatedInFuture;
        // The ledger has already executed the request.
        // `duplicate_of` field is equal to the index of the block containing the original transaction.
        #TxDuplicate : { duplicate_of: BlockIndex; }
    };

    public type TransferResult = {
        #Ok : BlockIndex;
        #Err : TransferError;
    };

    public type Error = {
        #NotInAllowlist;
        #TokenNotFound : Principal;
        #IndexNotFound : Nat;
    };

    public type Access = {
        // Denotes a public event without restrictions.
        #Public;
        // Denotes an event with limited access.
        #Private : Allowlist;
    };

    public type MetaData = {
        // Name of the event.
        name        : EventName;
        // Description of the event.
        description : Text;
        // Start of the event.
        startsAt    : Time;
        // End of the event.
        endsAt      : Time;
        // Price of 1 token.
        price       : NNSTypes.ICP;
        // The details of the collection.
        details     : CollectionDetails;
    };

    public type Data = MetaData and {
        // The access (type) of the event. Can be either:
        // - #Public  : accessible for everyone.
        // - #Private : only accessible by principals in the allowlist.
        accessType  : Access;
    };

    public type Result<T> = Result.Result<T, Error>;

    public type Event  = (token : Principal, data : Data, index : Nat);

    public type BlockIndex = Nat64;

    public type Allowlist = [(user : Principal, spots : Spots)];

    private type Spots     = ?Int;

    private type EventName = Text;

    private type Time      = Int;

    public type CollectionDetails = {
        iconImageUrl           : URL;
        bannerImageUrl         : URL;
        previewImageUrl        : URL;
        descriptionMarkdownUrl : URL;
    };

    private type URL       = Text;
};
