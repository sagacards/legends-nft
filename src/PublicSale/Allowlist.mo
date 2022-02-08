import HashMap "mo:base/HashMap";

import AccountIdentifier "mo:principal/AccountIdentifier";

import Types "types";

module {
    public func isInAllowlist(
        caller    : Principal,
        allowlist : HashMap.HashMap<Types.AccountIdentifier, Nat8>
    ) : ?Types.AccountIdentifier {
        let accountId = AccountIdentifier.fromPrincipal(caller, null); // 0-subaccount
        switch (allowlist.get(accountId)) {
            case (?n) {
                if (n == 0) {
                    // Just a double check.
                    allowlist.delete(accountId);
                    null;
                } else ?accountId;
            };
            case (_) null;
        };
    };

    public func consumeAllowlist(accountId : Types.AccountIdentifier, allowlist : HashMap.HashMap<Types.AccountIdentifier, Nat8>) {
        switch (allowlist.get(accountId)) {
            case (?n) if (n > 0) allowlist.put(accountId, n - 1) else allowlist.delete(accountId);
            case (_)  assert(false);
        };
    };
};
