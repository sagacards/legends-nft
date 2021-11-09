#!/bin/zsh

file=${1}
tags=("${(@s/ /)2}")
description=${3}
threshold=${4:-100000}
network=${5:-local}

filename=$(echo $file | sed -E "s/.+\///")
fileextension=$(echo $file | sed -E "s/.+\.//")

echo "Emptying buffer..."
dfx canister --network $network call legends uploadClear

i=0
byteSize=${#$(od -An -v -tuC $file)[@]}
echo "Uploading asset \"$filename\", size: $byteSize"
while [ $i -le $byteSize ]; do
    echo "chunk #$(($i/$threshold+1))..."
    dfx canister --network $network call legends upload "( vec {\
        vec { $(for byte in ${(j:;:)$(od -An -v -tuC $file)[@]:$i:$threshold}; echo "$byte;") };\
    })"
    i=$(($i+$threshold))
done
echo "Finalizing asset \"$filename\""
dfx canister --network $network call legends uploadFinalize "(\
    \"image/$fileextension\",\
    record {\
        \"filename\" = \"$filename\";\
        \"tags\" = vec { $(for tag in $tags; echo \"$tag\"\;) };\
        \"description\" = \"$description\";\
    }\
)"