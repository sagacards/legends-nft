#!/bin/zsh
canister=${1:-charlie}
network=${2:-local}

confname=$canister && [[ $canister == "charlie" || $canister == "foxtrot" ]] && confname="test"

# Confirm before deploying to mainnet
if [[ $network != "local" ]]
then
    echo "Confirm mainnet whitelist (WARNING: NOT IDEMPOTENT)"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) exit;;
        esac
    done
fi

# Configure presale allow list
# TODO: having this here is a problem, because with the current system subsequent runs of this command are not idempotent because they ignore current state

whitelist="./config/whitelists/$confname.csv"
[ ! -f $whitelist ] && { echo "$whitelist file not found"; exit 99; }
OLDIFS=$IFS
IFS=','
payload="(vec {"
{
	read # skip headers
	while read account count note
	do
		if [[ $account == "" ]] continue # skip empty lines
        payload="$payload record {\"$account\"; $count : nat8};"
	done
} < $whitelist
IFS=$OLDIFS
payload="$payload})"

dfx canister --network $network call $canister setAllowlist $payload