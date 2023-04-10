pragma ton-solidity >= 0.58.0;

library NftGas {
    uint128 constant TARGET_COLLECTION_BALANCE = 0.5 ton;
    uint128 constant TARGET_NFT_BALANCE = 0.3 ton;
    uint128 constant NFT_DEPLOY_VALUE = 0.8 ton;
    uint128 constant NFT_MINT_VALUE = 1 ton;
    uint128 constant INDEX_DEPLOY_VALUE = 0.15 ton;
    uint128 constant INDEX_DESTROY_VALUE = 0.1 ton;
    uint128 constant COLLECTION_ONTOKENBURNED_VALUE = 0.1 ton;
    uint128 constant DISPLAY_NAME_COLLECTION_BALANCE = 1 ton;
    uint128 constant COLLECTION_ON_DISPLAY_NAME_CREATED_VALUE = 0.1 ton;
}