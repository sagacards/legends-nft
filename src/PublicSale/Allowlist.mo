import Array "mo:base/Array";
import Blob "mo:base/Blob";
import HashMap "mo:base/HashMap";

import AccountBlob "mo:principal/blob/AccountIdentifier";

import Types "types";

module {
    public func isInAllowlist(
        caller    : Principal,
        allowlist : HashMap.HashMap<Types.AccountIdentifier, Nat8>
    ) : ?Types.AccountIdentifier {
        let subAccount = Array.init<Nat8>(32, 0);

        var i : Nat8 = 0;
        while (i < 10) {
            subAccount[31] := i;
            let accountId = Blob.toArray(AccountBlob.fromPrincipal(caller, ?Array.freeze(subAccount)));
            switch (allowlist.get(accountId)) {
                case (?n) {
                    if (n != 0) return ?accountId;
                    // Just a double check.
                    allowlist.delete(accountId);
                };
                case (_) {};
            };
            i += 1;
        };
        return null;
    };

    public func consumeAllowlist(accountId : Types.AccountIdentifier, allowlist : HashMap.HashMap<Types.AccountIdentifier, Nat8>) {
        switch (allowlist.get(accountId)) {
            case (?n) if (n > 0) allowlist.put(accountId, n - 1) else allowlist.delete(accountId);
            case (_)  assert(false);
        };
    };
};
