pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './modules/TIP4_1/TIP4_1Nft.sol';
import './modules/TIP4_2/TIP4_2Nft.sol';
import './modules/TIP4_3/TIP4_3Nft.sol';
import './libraries/MsgFlag.sol';
import './libraries/NftGas.sol';
import './interfaces/IMultiTokenNftBurn.sol';
import './interfaces/IMultiTokenNft.sol';

import './interfaces/INFTAcceptBurnCallback.sol';

contract Nft is TIP4_1Nft, TIP4_2Nft, TIP4_3Nft, IMultiTokenNftBurn, IMultiTokenNft {

    uint128 _tokenSupply;

    constructor(
        address owner,
        address sendGasTo,
        uint128 remainOnNft,
        string json,
        uint128 indexDeployValue,
        uint128 indexDestroyValue,
        TvmCell codeIndex,
        uint128 tokenSupply
    ) TIP4_1Nft(
        owner,
        sendGasTo,
        remainOnNft
    ) TIP4_2Nft (
        json
    ) TIP4_3Nft (
        indexDeployValue,
        indexDestroyValue,
        codeIndex
    ) public {
        tvm.accept();
        _tokenSupply = tokenSupply;
        _supportedInterfaces[bytes4(tvm.functionId(IMultiTokenNft.multiTokenSupply))] = true;
    }

    function multiTokenSupply() external view override responsible returns (uint128 count) {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } (_tokenSupply);
    }

    function burnToken(
        uint128 count,
        uint256 id,
        address owner,
        TvmCell payload
    ) external responsible override returns (uint128 tokenSupply, TvmCell next) {
        require(msg.sender == _collection);
        _tokenSupply -= count;
        return { value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED } (_tokenSupply, payload);
    }

    function _beforeTransfer(
        address to, 
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._beforeTransfer(to, sendGasTo, callbacks);
    }   

    function _afterTransfer(
        address to, 
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._afterTransfer(to, sendGasTo, callbacks);
    }   

    function _beforeChangeOwner(
        address oldOwner, 
        address newOwner,
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._beforeChangeOwner(oldOwner, newOwner, sendGasTo, callbacks);
    }   

    function _afterChangeOwner(
        address oldOwner, 
        address newOwner,
        address sendGasTo, 
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._afterChangeOwner(oldOwner, newOwner, sendGasTo, callbacks);
    }

    function burn(address dest) external internalMsg virtual onlyManager {
        tvm.accept();
        INFTAcceptBurnCallback(_collection).onAcceptNFTBurn{
            value: NftGas.COLLECTION_ONTOKENBURNED_VALUE,
            bounce: false,
            flag: 0
        }(_id, _owner, _manager);
        
        _destructIndex(dest);
        selfdestruct(dest);
    }
}