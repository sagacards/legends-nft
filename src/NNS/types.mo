import Admins "../Admins";

module {

    public type State = {
        _Admins : Admins.Admins;
    };

    // Amount of ICP tokens, measured in 10^-8 of a token.
    public type ICP = {
        e8s : Nat64;
    };

    // Number of nanoseconds from the UNIX epoch (00:00:00 UTC, Jan 1, 1970).
    public type Timestamp = {
        timestamp_nanos: Nat64;
    };

    // AccountIdentifier is a 32-byte array.
    // The first 4 bytes is big-endian encoding of a CRC32 checksum of the last 28 bytes.
    public type AccountIdentifier = Blob;

    // Subaccount is an arbitrary 32-byte byte array.
    // Ledger uses subaccounts to compute the source address, which enables one
    // principal to control multiple ledger accounts.
    public type SubAccount = Blob;

    // Sequence number of a block produced by the ledger.
    public type BlockIndex = Nat64;

    // An arbitrary number associated with a transaction.
    // The caller can set it in a `transfer` call as a correlation identifier.
    public type Memo = Nat64;

    // Arguments for the `transfer` call.
    public type TransferArgs = {
        // Transaction memo.
        // See comments for the `Memo` type.
        memo: Memo;
        // The amount that the caller wants to transfer to the destination address.
        amount: ICP;
        // The amount that the caller pays for the transaction.
        // Must be 10000 e8s.
        fee: ICP;
        // The subaccount from which the caller wants to transfer funds.
        // If null, the ledger uses the default (all zeros) subaccount to compute the source address.
        // See comments for the `SubAccount` type.
        from_subaccount: ?SubAccount;
        // The destination account.
        // If the transfer is successful, the balance of this account increases by `amount`.
        to: AccountIdentifier;
        // The point in time when the caller created this request.
        // If null, the ledger uses current IC time as the timestamp.
        created_at_time: ?Timestamp;
    };

    public type TransferError = {
        // The fee that the caller specified in the transfer request was not the one that the ledger expects.
        // The caller can change the transfer fee to the `expected_fee` and retry the request.
        #BadFee : { expected_fee : ICP; };
        // The account specified by the caller doesn't have enough funds.
        #InsufficientFunds : { balance: ICP; };
        // The request is too old.
        // The ledger only accepts requests created within a 24 hours window.
        // This is a non-recoverable error.
        #TxTooOld : { allowed_window_nanos: Nat64 };
        // The caller specified `created_at_time` that is too far in future.
        // The caller can retry the request later.
        #TxCreatedInFuture : Null;
        // The ledger has already executed the request.
        // `duplicate_of` field is equal to the index of the block containing the original transaction.
        #TxDuplicate : { duplicate_of: BlockIndex; };
    };

    public type TransferResult = {
        #Ok : BlockIndex;
        #Err : TransferError;
    };

    // Arguments for the `account_balance` call.
    public type AccountBalanceArgs = {
        account: AccountIdentifier;
    };

    // service : {
    // Transfers tokens from a subaccount of the caller to the destination address.
    // The source address is computed from the principal of the caller and the specified subaccount.
    // When successful, returns the index of the block containing the transaction.
    // transfer : (TransferArgs) -> (TransferResult);

    // Returns the amount of ICP on the specified account.
    // account_balance : (AccountBalanceArgs) -> (ICP) query;
    // }

    public type CanisterId = Principal;

    public type BlockHeight = Nat64;

    public type TransactionNotification = {
        from: Principal;
        from_subaccount: ?SubAccount;
        to: CanisterId;
        to_subaccount: ?SubAccount;
        block_height: BlockHeight;
        amount: ICP;
        memo: Memo;
    };

    public type NNS = actor {
        // Transfers tokens from a subaccount of the caller to the destination address.
        // The source address is computed from the principal of the caller and the specified subaccount.
        // When successful, returns the index of the block containing the transaction.
        transfer : shared (TransferArgs) -> async TransferResult;

        // Returns the amount of ICP on the specified account.
        account_balance : shared query AccountBalanceArgs -> async ICP;
    };

    // ockk2-xaaaa-aaaai-aaaua-cai

    public type TimeStamp = { timestamp_nanos : Nat64 };

    public type Hash = ?{ inner : [Nat8] };

    public type Block = {
        transaction : Transaction;
        timestamp : TimeStamp;
        parent_hash : Hash;
    };

    public type Certification = [Nat8];

    public type Transaction = {
        memo : Memo;
        created_at_time : TimeStamp;
        transfer : Transfer;
    };

    public type Transfer = {
        #Burn : { from : Text; amount : ICP };
        #Mint : { to : Text; amount : ICP };
        #Send : {
        to : Text;
        from : Text;
        amount : ICP;
        };
    };

    public type TipOfChain = {
        certification : ?Certification;
        tip_index : BlockHeight;
    };

    public type BlockProxy = actor {
        block : shared Nat64 -> async {
            #Ok : { #Ok : Block; #Err : CanisterId };
            #Err : Text;
        };
        tip_of_chain : shared () -> async { #Ok : TipOfChain; #Err : Text };
    };

};