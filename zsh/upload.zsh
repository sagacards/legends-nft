#!/bin/zsh
PATH=$PATH:/bin/:/usr/bin:/usr/local/bin

file=${1}
filename=$(echo $file | sed -E "s/.+\///")
fileextension=$(echo $file | sed -E "s/.+\.//")
name=${2}
tags=(${(@s/ /)3})
description=${4}
mime=${5:-image/$fileextension}
canister=${6:-legends-test}
network=${7:-local}
threshold=${8:-250000}

byteSize=${#$(od -An -v -tuC $file)[@]}

b="\e[1A\e[K"
log_line="Uploading $name $filename ($(( $byteSize / 1024 ))kb ($mime))"

echo "$log_line"

echo "$log_line ...Emptying buffer"
dfx canister --network $network call $canister uploadClear >> ./zsh/upload_log.txt

echo "$log_line ...Uploading"
i=0
while [ $i -le $byteSize ]; do
    echo "$log_line ...Uploading #$(($i/$threshold+1))/$(($byteSize/$threshold+1))"
    dfx canister --network $network call $canister upload "( vec {\
        vec { $(for byte in ${(j:;:)$(od -An -v -tuC $file)[@]:$i:$threshold}; echo "$byte;") };\
    })" >> ./zsh/upload_log.txt
    i=$(($i+$threshold))
done

echo "$log_line ...Finalizing"
tags=$(echo $tags | sed -e 's/^"//' -e 's/"$//')
tags=(${(@s/ /)tags})
dfx canister --network $network call $canister uploadFinalize "(\
    \"\",\
    record {\
        \"name\" = $name;\
        \"filename\" = \"$filename\";\
        \"tags\" = vec { $(for tag in $tags; echo "\"$tag\";") };\
        \"description\" = $description;\
    }\
)" >> ./zsh/upload_log.txt

echo "$log_line ...OK"