# Saga Legends NFT Canister

![Preview](preview.png)

>    Collectible Major Arcana for Early Saga Adopters.    
>    https://legends.saga.cards.

Each Legend is an individual canister using the NFT code found in this repository.

## Uploading Assets

```
dfx start --clean --background
dfx deploy
zsh upload.zsh path-to-file.jpg "tag1 tag2" "A description of the asset."
```

## Ledger

Each canister maintains a ledger of ownership for each NFT.

- Admin mint
- Supporter mint
- Staged sales
