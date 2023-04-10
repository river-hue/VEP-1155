pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "../modules/TIP6/TIP6.sol";
import '../interfaces/IRoyaltyInfo.sol';

import '../libraries/Consts.sol';
import "../libraries/MsgFlag.sol";

abstract contract RoyaltySupport is TIP6, IRoyaltyInfo {

    address _royaltyAddress;
    uint128 _royalty;

    function _initRoyalty(address royaltyAddress, uint128 royalty) internal {
        _royalty = royalty;
        _royaltyAddress = royaltyAddress;

        _supportedInterfaces[bytes4(tvm.functionId(IRoyaltyInfo.royaltyInfo))] = true;
    }    

    function royaltyInfo(uint128 salePrice)
        virtual override external view responsible returns(address receiver, uint128 royaltyAmount) {
        return {
            value: 0,
            bounce: false,
            flag: MsgFlag.REMAINING_GAS
        } (_royaltyAddress, math.muldiv(salePrice, _royalty, Consts.PERCENT_PRECISION));
    }
}