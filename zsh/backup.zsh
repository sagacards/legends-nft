#!/bin/zsh
canister=${1:-charlie}
network=${2:-local}

funcs=("publicSaleBackup" "tokensBackup" "paymentsRaw" "listings" "transactions" "readPending")

mkdir -p backups/$canister

for func in $funcs; dfx canister --network $network call $canister $func > backups/$canister/$func.txt