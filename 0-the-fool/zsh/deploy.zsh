canister=${1:-legends-staging}
network=${2:-local}

caprouter="null" && [[ $network == local ]] && caprouter="rwlgt-iiaaa-aaaaa-aaaaa-cai"

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

if [[ $canister = "legends-staging" ]]
then
    dfx deploy --network $network $canister --argument "(
        principal \"dklxm-nyaaa-aaaaj-qajza-cai\",
        $caprouter,
        record {
            \"supply\" = 117 : nat16;
            \"name\" = \"Legends Test Canister\";
            \"flavour\" = \"For testing only.\";
            \"description\" = \"...\";
            \"artists\" = vec { \"Jorgen\" };
        }
    )"
else
    echo "Unrecognized canister."
fi