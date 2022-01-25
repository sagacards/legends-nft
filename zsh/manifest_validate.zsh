#!/bin/zsh
PATH=$PATH:/bin/:/usr/bin:/usr/local/bin

canister=${1:-legends-test}
network=${2:-local}

# Get supply
supply=117

# Get canister ID
canisters_json="./canister_ids.json" && [[ $network == local ]] && canisters_json=".dfx/local/canister_ids.json"
canister_id=$(jq ".\"$canister\".\"$network\"" $canisters_json | tr -d '"');

host="https://$canister_id.raw.ic0.app"

# Make sure every token has a non-zero html app at its root.
errors=0
missing_tokens=""
echo "Validating token preview apps...\n"
echo "tests, code, mime, size, errors, missing"
for i in {0..$supply}; do
    # curl -s -I "$host/$i"
    resp=$(curl -s -I --silent $host/$i);
    [[ $resp =~ 'Content-Type: ([a-zA-Z0-9\/]+)' ]]
    mime=$match[1]
    [[ $resp =~ 'HTTP\/[0-9\.]+ ([0-9]+)' ]]
    code=$match[1]
    [[ $resp =~ 'Content-Length: ([0-9]+)' ]]
    size=$match[1]
    if [[ $code != 200 || $size < 500000 || $mime != "text/html" ]]
    then
        errors=$((errors+1))
        missing_tokens="$missing_tokens$i "
    fi
    echo "$((i+1))/$supply, $code, $mime\t$size, $errors, $missing_tokens"
done;

echo "OK\n"

# Make sure every token has a static image version. We also check that the size of the file is an exact match with our local version.
# TODO: reference the local metadata configuration?
errors=0
missing_tokens=""
echo "Validating token static images...\n"
echo "token, code, size, local size, errors, missing"
for i in {0..$supply}; do
    resp=$(curl -s -I --silent $host/$i.webp);
    [[ $resp =~ 'HTTP\/[0-9\.]+ ([0-9]+)' ]]
    code=$match[1]
    [[ $resp =~ 'legends-filename: (.+\.[a-zA-Z0-9]+)' ]]
    file=$match[1]
    file_local=$(find ./art -name "$file" | awk '{print $1}' )
    
    [[ $resp =~ 'Content-Length: ([0-9]+)' ]]
    size=$match[1]
    size_local=$(wc -c $file_local | awk '{print $3}')
    if [[ $code != 200 || ! -f $file_local || $size_local != $((size)) ]]
    then
        errors=$((errors+1))
        missing_tokens="$missing_tokens$i "
    fi
    echo "$((i+1))/$supply, $code, $size, $size_local, $errors, $missing_tokens"
done;

echo "OK\n"

# Make sure every token has an animated version.
errors=0
missing_tokens=""
echo "Validating token animations...\n"
echo "token, code, size, local size, errors, missing"
for i in {0..$supply}; do
    resp=$(curl -s -I --silent $host/$i.webm);
    [[ $resp =~ 'HTTP\/[0-9\.]+ ([0-9]+)' ]]
    code=$match[1]
    [[ $resp =~ 'legends-filename: (.+\.[a-zA-Z0-9]+)' ]]
    file=$match[1]
    file_local=$(find ./art -name "$file" -print | head -n 1)
    [[ $resp =~ 'Content-Length: ([0-9]+)' ]]
    size=$match[1]
    size_local=$(wc -c $file_local | awk '{print $1}')
    if [[ $code != 200 || ! -f $file_local || $size_local != $((size)) ]]
    then
        errors=$((errors+1))
        missing_tokens="$missing_tokens$i "
    fi
    echo "$((i+1))/$supply, $code, $size, $size_local, $errors, $missing_tokens"
done;

# Make sure that each legends-manifest returns a valid json file
errors=0
missing_tokens=""
echo "Validating token animations...\n"
echo "token, valid, errors, missing"
for i in {0..$supply}; do
    resp=$(curl -s $host/$i.json);
    e=$(echo $resp | jq empty 2>&1; echo $?);
    valid=false
    if (( $e == 0 )); then
        valid=true
    fi
    echo "$((i+1))/$supply, $valid, $errors, $missing_tokens"
done;

# Make sure each file in the manifest returns a non-empty 200 response, and that the return size matches the local size
errors=0
missing_assets=""
manifest="./config/manifests/$canister.csv"
[ ! -f $manifest ] && { echo "$manifest file not found"; exit 99; }
echo "Validating all assets in the manifest...\n"
echo "token, file, code, size, local size, errors, missing"
OLDIFS=$IFS
IFS=','
{
	read # skip headers
	while read file name tags description mime
	do
		if [[ $file == "" ]] continue # skip empty lines
        filename=$(echo $file | sed -E "s/.+\///")
		resp=$(curl -s -I --silent $host/assets/$filename);
        [[ $resp =~ 'HTTP\/[0-9\.]+ ([0-9]+)' ]]
        code=$match[1]
        [[ $resp =~ 'Content-Length: ([0-9]+)' ]]
        size=$match[1]
        size_local=$(wc -c $file | awk '{print $1}')
        if [[ $code != 200 || $size_local != $((size)) ]]
        then
            errors=$((errors+1))
            missing_assets="$missing_assets$filename "
        fi
        echo "$((i+1))/$supply, $filename, $code, $size, $size_local, $errors, $missing_assets"
	done
} < $manifest
IFS=$OLDIFS

# TODO: Test wallet specific URLs