#!/bin/zsh
for i in {0..116}; dfx canister call legends mint "principal \"$(dfx identity get-principal)\""