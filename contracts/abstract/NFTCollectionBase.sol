pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '../modules/TIP4_2/TIP4_2Collection.sol';
import '../modules/TIP4_3/TIP4_3Collection.sol';

import '../interfaces/INFTAcceptBurnCallback.sol';

import "../errors/TokenErrors.sol";

abstract contract NFTCollectionBase is
   TIP4_2Collection,
   TIP4_3Collection,
   INFTAcceptBurnCallback
{
    constructor(
        TvmCell codeNft,
        TvmCell codeIndex,
        TvmCell codeIndexBasis,
        string json
    ) TIP4_1Collection (
        codeNft
    ) TIP4_2Collection (
        json
    ) TIP4_3Collection (
        codeIndex,
        codeIndexBasis
    ) public {
    }

    function onAcceptNFTBurn(uint256 id, address owner, address manager) external internalMsg virtual override {
        require(msg.sender == _resolveNft(id));
        emit NftBurned(id, msg.sender, owner, manager);
        _totalSupply--;
    }

    /// Overrides standard method, because Nft contract is changed
    function _buildNftState(
        TvmCell code,
        uint256 id
    ) internal virtual override(TIP4_2Collection, TIP4_3Collection) pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: TIP4_3Nft,
            varInit: {_id: id},
            code: code
        });
    }
}