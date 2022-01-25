#!/bin/zsh
canister=${1:-legends-test}
network=${2:-local}

# Configure canister metadata
metadata="./config/metadata/$canister.csv"
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

dfx canister --network $network call $canister configureLegends $payload

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
