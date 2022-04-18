#!/bin/zsh
canister=${1:-charlie}
network=${2:-local}

confname=$canister && [[ $canister == "charlie" || $canister == "foxtrot" ]] && confname="test"

# Confirm before deploying to mainnet
if [[ $network != "local" ]]
then
    echo "Confirm mainnet launch. WARNING: RECONFIGURING A LIVE CANISTER AFTER SHUFFLING CAN CAUSE HUGE, PERMANENT DAMAGE"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) exit;;
        esac
    done
fi

# Configure canister metadata
metadata="./config/metadata/$confname.csv"
[ ! -f $metadata ] && { echo "$metadata file not found"; exit 99; }
OLDIFS=$IFS
IFS=','
payload="(vec {"
{
	read # skip headers
	while read border back ink mask stock
	do
		if [[ $border == "" ]] continue # skip empty lines
        payload="$payload record { border = \"$border\"; back = \"$back\"; ink = \"$ink\"; mask = \"$mask\"; stock = \"$stock\"; normal = \"leaf\"; };"
	done
} < $metadata
IFS=$OLDIFS
payload="$payload})"

dfx canister --network $network call $canister configureMetadata $payload


# Initialize CAP
dfx canister --network $network call $canister init


# Configure colors
colors="./config/colors/$confname.csv"
[ ! -f $colors ] && { echo "$colors file not found"; exit 99; }
OLDIFS=$IFS
IFS=','
payload="(vec {"
{
	read # skip headers
	while read name base specular emissive background
	do
		if [[ $name == "" ]] continue # skip empty lines
        payload="$payload record { name = \"$name\"; base = \"$base\"; specular = \"$specular\"; emissive = \"$emissive\"; background = \"$background\"; };"
	done
} < $colors
IFS=$OLDIFS
payload="$payload})"

dfx canister --network $network call $canister configureColors $payload


# Configure stocks
colors="./config/stocks/$confname.csv"
[ ! -f $colors ] && { echo "$colors file not found"; exit 99; }
OLDIFS=$IFS
IFS=','
payload="(vec {"
{
	read # skip headers
	while read name base specular emissive
	do
        if [[ $name == "" ]] continue # skip empty lines
        payload="$payload record { name = \"$name\"; base = \"$base\"; specular = \"$specular\"; emissive = \"$emissive\"; background = \"#000000\";  };"
	done
} < $colors
IFS=$OLDIFS
payload="$payload})"

dfx canister --network $network call $canister configureStockColors "$payload"
