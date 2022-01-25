# Saga Legends NFT Canister

![Preview](preview.png)

>    Collectible Major Arcana for Early Saga Adopters.    
>    https://legends.saga.cards.

This canister is a fairly complete NFT solution which generally follows the EXT standard. It may vary from other canisters using the EXT standard for lack of complete standards documentation. No guarantees that it matches your specific NFT use case.

**A Legends NFT example: [The Fool Mint #1](https://nges7-giaaa-aaaaj-qaiya-cai.raw.ic0.app/0)**

- [x] Maintains **ownership** ledger
- [x] Manages **assets** in this canister
- [x] Integrates [**CAP**](https://cap.ooo) for provinance and transaction history
- [x] Provides **public sale** functionality, with some support scripts
- [x] Interfaces with the **entrepot marketplace**
- [x] Works with **plug**, **stoic** and **earth** wallets
- [x] Provides functionality to **drain and restore** stable state
- [ ] Provide **payouts** from primary and secondary sales based on a per-canister configurable distribution map
- [ ] Integrate **covercode.ooo**

This single repository powers all of the legends NFTs, where each release is individually deployed to the IC (i.e. the fool is one canister, the magician is another, and so on.) This repo contains the source code of these canisters, as well as some scripts to help manage the deployment and configuration of the fleet of canisters that make up the legends series of NFTs.

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

Then you can deploy your new canister (this will use the canisters config) followed by uploading all of the assets from your manifest (this will take a while—benchmarked with the fool at ~2hr on mainnet and slightly less on local replica.)

- [ ] Add process pool to upload bash script and multiple upload buffers to canister to enable parallel uploads in order to cut upload times

```zsh
zsh/deploy.zsh my-new-canister somenet
zsh/manifest_upload.zsh my-new-canister somenet
```

Finally, the metadata for each legend needs to be configured:

```zsh
zsh/configure.zsh my-new-canister somenet
```

- [ ] Add metadata shuffling
- [ ] Improve metadata solution in general

Once the NFT canister is deployed, it should be submitted to [DAB](https://dab.ooo) so that it can be discovered by other wallets an dApps.

## Uploading Assets

Assets are stored with a basic set of metadata, including tags which provide an easy way to query those assets. The assets themselves are stored as byte buffers using the [asset-storage.mo](https://github.com/aviate-labs/asset-storage.mo) library.

After installing the NFT canister on the IC mainnet or local replica, you can use the upload zshell scripts in this repository to provision that canister with assets. The assets themselves are stored in a private art repository.

If you are creating a new set of art assets for a canister, after you've created all of said assets you will need to generate a new manifest file.

To begin the upload process, run the following command:

```zsh
# zsh/manifest_upload.zsh <CANISTER> <NETWORK>
zsh/manifest_upload.zsh legends-test ic
```

You may run into errors when using the upload script, if your shell cannot handle the chunk sizes. In that case, you should tweak the threshold parameter in [`zsh/upload.zsh`](zsh/upload.zsh#L13).

## Generating a Manifest

Many of the common assets you can simply copy from another manifest file. For batches of assets, you can use [`zsh/manifest_generate.zsh`](./zsh/manifest_generate.zsh) to help generate your manifest rows.

- [ ] node.js uploads and utility scripts (that's enough of zsh)

