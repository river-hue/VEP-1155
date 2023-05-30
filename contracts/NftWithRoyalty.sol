pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './Nft.sol';
import './abstract/RoyaltySupport.sol';

contract NftWithRoyalty is Nft, RoyaltySupport {

    constructor(
        address owner,
        address sendGasTo,
        uint128 remainOnNft,
        string json,
        uint128 indexDeployValue,
        uint128 indexDestroyValue,
        TvmCell codeIndex,
        address royaltyAddress,
        uint128 royalty,
        uint128 count
    ) Nft (
        owner,
        sendGasTo,
        remainOnNft,
        json,
        indexDeployValue,
        indexDestroyValue,
        codeIndex,
        count
    ) public {
        _initRoyalty(royaltyAddress, royalty);
    }
}