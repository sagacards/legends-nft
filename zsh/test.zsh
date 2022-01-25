#!/bin/zsh
PATH=$PATH:/bin/:/usr/bin:/usr/local/bin

canister=${1:-legends-test}
network=${2:-local}

# Get canister ID
canisters_json="./canister_ids.json" && [[ $network == local ]] && canisters_json=".dfx/local/canister_ids.json"
canister_id=$(jq ".\"$canister\".\"$network\"" $canisters_json | tr -d '"');

host="https://$canister_id.raw.ic0.app"

# State persists through upgrade
# - Ledger
# - Assets

# Unminted tokens don't render

# Validate NRI

# Preview assets match texture assets for each legend

# Non-admins cannot access any admin endpoints

# Backup methods are functional

# Complete a market listing and transaction (nns ledger? 🤮)

# Public sales work

# Entrepot works