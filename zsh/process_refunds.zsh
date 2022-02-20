#!/bin/zsh
PATH=$PATH:/bin/:/usr/bin:/usr/local/bin

canister=${1:-charlie}
network=${2:-local}

dfx canister --network $network call $canister publicSaleProcessRefunds "(vec { $(node 'node/process-refunds.js' 0 10) })"