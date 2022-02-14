#!/bin/zsh
canister=${1:-charlie}
network=${2:-local}

confname=$canister && [[ $canister == "charlie" || $canister == "foxtrot" ]] && confname="test"

# Confirm before deploying to mainnet
if [[ $network != "local" ]]
then
    echo "Confirm mainnet uploads"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) break;;
            No ) exit;;
        esac
    done
fi

manifest="./config/manifests/$confname.csv"
[ ! -f $manifest ] && { echo "$manifest file not found"; exit 99; }

payload="(vec {"

OLDIFS=$IFS
IFS=','
{
	read # skip headers
	while read file name tags description mime
	do
		if [[ $file == "" ]] continue # skip empty lines
        tags=$(echo $tags | sed -e 's/^"//' -e 's/"$//')
        tags=(${(@s/ /)tags})
        filename=$(echo $file | sed -E "s/.+\///")
        payload="$payload record { \"$filename\"; vec { $(for tag in $tags; echo "\"$tag\";") } };"
	done
} < $manifest
IFS=$OLDIFS

payload="$payload})"

dfx canister --network $network call $canister assetsTag $payload