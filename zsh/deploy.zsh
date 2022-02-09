#!/bin/zsh
PATH=$PATH:/bin/:/usr/bin:/usr/local/bin

canister=${1:-charlie}
network=${2:-local}

wallet="" && [[ $network == local ]] && wallet=--no-wallet
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

# Override cap router canister locally
caprouter="null"
if [[ $network == local ]]
then
    cap_dfx_path=~/Projects/cap/.dfx/local/canister_ids.json
    [ -f $cap_dfx_path ] && caprouter="opt $(jq '."ic-history-router"."local"' $cap_dfx_path)"
fi

# Get or create canister ID
canister_id=
canisters_json="./canister_ids.json" && [[ $network == local ]] && canisters_json=".dfx/local/canister_ids.json"
while [ ! $canister_id ];
do
    # Find canister ID in local json files
    [ -f $canisters_json ] && canister_id=$(jq ".\"$canister\".\"$network\"" $canisters_json);
    if [[ ! $canister_id ]]
    then
        # Create the canister
        dfx canister --network $network $wallet create $canister;
    fi
done

# Deploy using config manifest as arguments
config="./config/canisters/$confname.json"
[ ! -f $config ] && { echo "$config file not found"; exit 99; }
IFS=$'\n'
read -r -d$'\1' supply name flavour description artists price_private price_public <<< $(jq -r '.supply, .name, .flavour, .description, .artists, .private_sale_price_e8s, .public_sale_price_e8s' $config)
dfx deploy $wallet --network $network $canister --argument "(
    principal $canister_id,
    $caprouter,
    record {
        \"supply\" = $supply : nat16;
        \"name\" = \"$name\";
        \"flavour\" = \"$flavour\";
        \"description\" = \"$description\";
        \"artists\" = $artists;
    }
)"

dfx canister --network $network call $canister configurePublicSalePrice "( $price_private : nat64, $price_public : nat64 )"