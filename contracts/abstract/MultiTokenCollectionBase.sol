pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../interfaces/IMultiTokenCollection.sol";
import "../interfaces/IMultiTokenBurnCallback.sol";
import "../interfaces/IMultiTokenAcceptBurnCallback.sol";
import '../interfaces/IMultiTokenNftBurn.sol';

import "../modules/TIP6/TIP6.sol";

import '../libraries/MsgFlag.sol';


abstract contract MultiTokenCollectionBase is
    TIP6,
    IMultiTokenCollection,
    IMultiTokenAcceptBurnCallback
{
    TvmCell _tokenCode;

    constructor(
        TvmCell tokenCode,
        address remainingGasTo
    ) public {
        tvm.accept();

        _tokenCode = tokenCode;

        _supportedInterfaces[bytes4(tvm.functionId(ITIP6.supportsInterface))] = true;
        _supportedInterfaces[
            bytes4(tvm.functionId(IMultiTokenCollection.multiTokenWalletCode)) ^
            bytes4(tvm.functionId(IMultiTokenCollection.multiTokenCodeHash)) ^
            bytes4(tvm.functionId(IMultiTokenCollection.multiTokenWalletAddress))
        ] = true;

        tvm.rawReserve(_targetBalance(), 0);

        if (remainingGasTo.value != 0) {
            remainingGasTo.transfer({
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            });
        }
    }

    function multiTokenWalletCode(uint256 tokenId, bool isEmpty) virtual override external view responsible returns (TvmCell code)
    {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } (_buildTokenCode(address(this), tokenId, isEmpty));
    }

    function multiTokenCodeHash(uint256 tokenId, bool isEmpty) virtual override external view responsible returns (uint256 codeHash)
    {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } (tvm.hash(_buildTokenCode(address(this), tokenId, isEmpty)));
    }

    function multiTokenWalletAddress(uint256 id, address owner) virtual override external view responsible returns (address token)
    {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } (_resolveToken(id, owner));
    }

    /// @notice build token code used TvmCell token code & salt (address collection) ... 
    /// ... to create unique token address BC token code & id can be repeated
    /// @param collection - collection address
    /// @return TvmCell tokenCode 
    /// about salt read more here (https://github.com/tonlabs/TON-Solidity-Compiler/blob/master/API.md#tvmcodesalt)
    function _buildTokenCode(address collection, uint256 tokenId, bool isEmpty) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(collection);
        salt.store(tokenId);
        salt.store(isEmpty);

        return tvm.setCodeSalt(_tokenCode, salt.toCell());
    }

    /// @notice Resolve token address by collection address, token id and owner address
    /// @param id Unique token number
    /// @param owner Owner contract address
    function _resolveToken(uint256 id, address owner) internal virtual view returns (address token) {
        TvmCell state = _buildTokenState(id, owner);
        token = address(tvm.hash(state));
    }

    /// @notice Generates a StateInit from code, data and owner
    /// @param id Unique token number
    /// @param owner Owner contract address
    /// @return TvmCell object - stateInit
    /// about tvm.buildStateInit read more here (https://github.com/tonlabs/TON-Solidity-Compiler/blob/master/API.md#tvmbuildstateinit)
    function _buildTokenState(uint256 id, address owner) internal virtual view returns (TvmCell);

    /// @notice Decrease totalSupply by 1
    function _decreaseTotalSupply() internal virtual;

    function _reserve() internal pure returns (uint128) {
        return math.max(address(this).balance - msg.value, _targetBalance());
    }

    function _targetBalance() virtual internal pure returns (uint128);
}