#!/bin/zsh
PATH=$PATH:/bin/:/usr/bin:/usr/local/bin

canister=${1:-charlie}
network=${2:-local}

# canister_id=$(jq ".\"$canister\".\"$network\"" $canisters_json | tr -d '"');

admin=$(node ./node/getPrincipal admin)

echo "Creating a canister admin $admin"

dfx canister --network $network call $canister addAdmin "principal \"$admin\""
