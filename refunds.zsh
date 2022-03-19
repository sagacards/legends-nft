#!/bin/zsh
canister=${1:-1-the-magician}
network=${2:-ic}

manifest="./refunds.csv"
[ ! -f $manifest ] && { echo "$manifest file not found"; exit 99; }
echo "starting refunds"

OLDIFS=$IFS
IFS=','
{
	read # skip headers
	while read account balance
	do
		if [[ $account == "" ]] continue # skip empty lines
        echo "refunding $account $balance"
		dfx canister --network $network call $canister nnsTransfer "(record { \"e8s\" = $(echo "$balance")_00_000_000}, \"$account\", 0)"
	done
} < $manifest
IFS=$OLDIFS