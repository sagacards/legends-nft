#!/bin/zsh
network=${1:-local}

dfx canister --network $network call legends paymentsProcessRefunds "(vec { $(node 'node/process-refunds.js' 0 200) })"