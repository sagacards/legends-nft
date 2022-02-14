#!/bin/zsh
canister=${1:-charlie}
network=${2:-local}

confname=$canister && [[ $canister == "charlie" || $canister == "foxtrot" ]] && confname="test"

# Confirm before deploying to mainnet
if [[ $network != "local" ]]
then
    echo "Confirm mainnet launch"
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
	while read border back ink
	do
		if [[ $border == "" ]] continue # skip empty lines
        payload="$payload record { border = \"$border\"; back = \"$back\"; ink = \"$ink\"; };"
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

# Configure price

config="./config/canisters/$confname.json"
[ ! -f $config ] && { echo "$config file not found"; exit 99; }
read -r -d$'\1' price_private price_public <<< $(jq -r '.private_sale_price_e8s, .public_sale_price_e8s' $config)

dfx canister --network $network call $canister configurePublicSalePrice "( $price_private : nat64, $price_public : nat64 )"

# Configure NRI

if [[ $canister != "0-the-fool" ]]
then
    echo "No NRI data yet"
    exit
fi

dfx canister --network $network call $canister configureNri\
    "(vec {\
        record {\"back-fate\";           0.0000};\
        record {\"back-bordered-saxon\"; 0.5283};\
        record {\"back-worn-saxon\";     0.9434};\
        record {\"back-saxon\";          1.0000};\
        record {\"border-thin\";         0.0000};\
        record {\"border-bare\";         0.0000};\
        record {\"border-round\";        0.4615};\
        record {\"border-staggered\";    0.4615};\
        record {\"border-thicc\";        0.9231};\
        record {\"border-greek\";        0.9231};\
        record {\"border-worn-saxon\";   0.7692};\
        record {\"border-saxon\";        1.0000};\
        record {\"ink-copper\";          0.0000};\
        record {\"ink-silver\";          0.3333};\
        record {\"ink-gold\";            0.5833};\
        record {\"ink-canopy\";          0.8056};\
        record {\"ink-rose\";            0.8611};\
        record {\"ink-spice\";           0.9444};\
        record {\"ink-midnight\";        1.0000};\
    })"