#!/bin/zsh
canister=${1:-legends-test}
network=${2:-local}

manifest="./config/manifests/$canister.csv"
[ ! -f $manifest ] && { echo "$manifest file not found"; exit 99; }

OLDIFS=$IFS
IFS=','
{
	read # skip headers
	while read file name tags description mime
	do
		if [[ $file == "" ]] continue # skip empty lines
		zsh/upload.zsh $file \"$name\" \"$tags\" \"$description\" \"$mime\" $canister $network
	done
} < $manifest
IFS=$OLDIFS