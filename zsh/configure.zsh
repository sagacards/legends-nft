#!/bin/zsh
canister=${1:-legends-test}
network=${2:-local}

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

dfx canister --network $network call $canister configureLegends\
    "(vec {\

        record { border = \"saxon\"; back = \"saxon\"; ink = \"copper\"; };\
        record { border = \"saxon\"; back = \"saxon\"; ink = \"silver\"; };\
        record { border = \"saxon\"; back = \"saxon\"; ink = \"gold\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\"; ink = \"canopy\"; };\
        record { border = \"staggered\"; back = \"bordered-saxon\"; ink = \"rose\"; };\
        record { border = \"round\"; back = \"fate\"; ink = \"spice\"; };\
        record { border = \"staggered\"; back = \"fate\"; ink = \"midnight\"; };\

        record { border = \"thin\"; back = \"fate\"; ink = \"copper\"; };\
        record { border = \"thin\"; back = \"fate\"; ink = \"silver\"; };\
        record { border = \"bare\"; back = \"fate\"; ink = \"copper\"; };\
        record { border = \"bare\"; back = \"fate\"; ink = \"silver\"; };\
        record { border = \"round\"; back = \"fate\"; ink = \"copper\"; };\
        record { border = \"staggered\"; back = \"bordered-saxon\"; ink = \"gold\"; };\
        record { border = \"thicc\"; back = \"bordered-saxon\"; ink = \"copper\"; };\
        record { border = \"greek\"; back = \"bordered-saxon\"; ink = \"gold\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\"; ink = \"copper\"; };\
        record { border = \"saxon\"; back = \"saxon\"; ink = \"copper\"; };\

        record { border = \"thin\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"canopy\"; };\
        record { border = \"thin\"; back = \"fate\";	ink = \"spice\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"gold\"; };\
        record { border = \"thin\"; back = \"bordered-saxon\";	ink = \"canopy\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"canopy\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"canopy\"; };\
        record { border = \"bare\"; back = \"fate\";	ink = \"rose\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"gold\"; };\
        record { border = \"bare\"; back = \"bordered-saxon\";	ink = \"canopy\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"canopy\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"canopy\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"rose\"; };\
        record { border = \"round\"; back = \"fate\";	ink = \"spice\"; };\
        record { border = \"round\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"round\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"round\"; back = \"bordered-saxon\";	ink = \"gold\"; };\
        record { border = \"round\"; back = \"bordered-saxon\";	ink = \"canopy\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"canopy\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"rose\"; };\
        record { border = \"staggered\"; back = \"fate\";	ink = \"midnight\"; };\
        record { border = \"staggered\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"staggered\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"staggered\"; back = \"bordered-saxon\";	ink = \"gold\"; };\
        record { border = \"staggered\"; back = \"bordered-saxon\";	ink = \"rose\"; };\
        record { border = \"thicc\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thicc\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"thicc\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"thicc\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"thicc\"; back = \"fate\";	ink = \"rose\"; };\
        record { border = \"thicc\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"thicc\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"thicc\"; back = \"bordered-saxon\";	ink = \"gold\"; };\
        record { border = \"thicc\"; back = \"bordered-saxon\";	ink = \"rose\"; };\
        record { border = \"greek\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"greek\"; back = \"fate\";	ink = \"copper\"; };\
        record { border = \"greek\"; back = \"fate\";	ink = \"silver\"; };\
        record { border = \"greek\"; back = \"fate\";	ink = \"gold\"; };\
        record { border = \"greek\"; back = \"fate\";	ink = \"spice\"; };\
        record { border = \"greek\"; back = \"bordered-saxon\";	ink = \"copper\"; };\
        record { border = \"greek\"; back = \"bordered-saxon\";	ink = \"silver\"; };\
        record { border = \"greek\"; back = \"bordered-saxon\";	ink = \"gold\"; };\
        record { border = \"greek\"; back = \"bordered-saxon\";	ink = \"rose\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"copper\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"copper\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"silver\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"silver\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"gold\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"gold\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"canopy\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"rose\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"spice\"; };\
        record { border = \"worn-saxon\"; back = \"worn-saxon\";	ink = \"midnight\"; };\
        record { border = \"saxon\"; back = \"saxon\";	ink = \"copper\"; };\
        record { border = \"saxon\"; back = \"saxon\";	ink = \"silver\"; };\
        record { border = \"saxon\"; back = \"saxon\";	ink = \"gold\"; };\
        record { border = \"saxon\"; back = \"saxon\";	ink = \"spice\"; };\
        record { border = \"saxon\"; back = \"saxon\";	ink = \"midnight\"; };\
    })"