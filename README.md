# Saga Legends NFT Canister

![Preview](preview.png)

>    Collectible Major Arcana for Early Saga Adopters.    
>    https://legends.saga.cards.

This canister generally follows the EXT standard. It may vary from other canisters using the EXT standard for lack of complete standards documentation, but it is interoperable with Stoic Wallet, Plug Wallet, Earth Wallet, and the Entrepot Marketplace.

- [x] Manages assets in this canister
- [x] Integrates [CAP](https://cap.ooo) for provinance and transaction history

## Development & Deployment

```zsh
dfx start --clean --background
zsh/deploy.zsh
zsh/configure.zsh
```

You can specify network as well as which legend you would like to deploy using command line arguments like so:

```zsh
# zsh/deploy.zsh <CANISTER_NAME:legends-test> <NETWORK:local>
zsh/deploy.zsh legends-test local
```

To create a new legend canister, perform the following initial setup:

- add an entry to `dfx.json`
- clone the private art repository into this repo, and place all of the art assets there
- create a manifest for the art, and a config json for the canister
- make sure you use the same name string from `dfx.json` as the name of the config files

Then you can deploy your new canister (this will use the canisters config) followed by uploading all of the assets from your manifest (this will take a while—benchmarked with the fool at 29m on mainnet and 12m on local replica.)

```zsh
zsh/deploy.zsh my-new-canister somenet
zsh/manifest_upload.zsh my-new-canister somenet
```

Finally, the metadata for each legend needs to be configured:

```zsh
zsh/configure.zsh my-new-canister somenet
```

- [ ] Add metadata shuffling

## Uploading Assets

Assets are stored with a basic set of metadata, including tags which provide an easy way to query those assets. The assets themselves are stored as byte buffers using the [asset-storage.mo](https://github.com/aviate-labs/asset-storage.mo) library.

After installing the NFT canister on the IC mainnet or local replica, you can use the upload zshell scripts in this repository to provision that canister with assets. The assets themselves are stored in a private art repository.

If you are creating a new set of art assets for a canister, after you've created all of said assets you will need to generate a new manifest file.

To begin the upload process, run the following command:

```zsh
# zsh/manifest_upload.zsh <CANISTER> <MANIFEST_FILEPATH> <NETWORK>
zsh/manifest_upload.zsh legends-test ./art/manifest-0-the-fool.csv ic
```

You may run into errors when using the upload script, if your shell cannot handle the chunk sizes. In that case, you should tweak the threshold parameter in [`zsh/upload.zsh`](zsh/upload.zsh#L13).

## Generating a Manifest

Many of the common assets you can simply copy from another manifest file. For batches of assets, you can use [`zsh/manifest_generate.zsh`](./zsh/manifest_generate.zsh) to help generate your manifest rows.

- [ ] node.js uploads and utility scripts (that's enough of zsh)

