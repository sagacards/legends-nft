# Saga Legends NFT Canister

![Preview](preview.png)

>    Collectible Major Arcana for Early Saga Adopters.    
>    https://legends.saga.cards.

This canister generally follows the EXT standard. It may vary from other canisters using the EXT standard for lack of complete standards documentation, but it is interoperable with Stoic Wallet, Plug Wallet, Earth Wallet, and the Entrepot Marketplace.

- [x] Manages assets in this canister
- [x] Integrates [CAP](https://cap.ooo) for provinance and transaction history

## Development

```
dfx start --clean --background
dfx deploy
```

## Uploading Assets

Assets are stored with a basic set of metadata, including tags which provide an easy way to query those assets. The assets themselves are stored as byte buffers using the [asset-storage.mo](https://github.com/aviate-labs/asset-storage.mo) library.

A zsh script is provided to make uploading assets easy:

```
zsh upload.zsh path-to-file.jpg "tag1 tag2" "A description of the asset."
```

By default this script will run against your local replica, but you can pass in another parameter for network to the command above if you want to use mainnet.
