pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import '../modules/TIP4_3/interfaces/ITIP4_3NFT.sol';
import '../modules/TIP4_3/Index.sol';
import '../modules/TIP6/TIP6.sol';

import '@broxus/contracts/contracts/libraries/MsgFlag.tsol';

abstract contract TIP4_3NFT is ITIP4_3NFT, TIP6 {
    /// Values for deploy/destroy
    uint128 _indexDeployValue;
    uint128 _indexDestroyValue;

    /// TvmCell object code of Index contract
    TvmCell _codeIndex;

    function _initIndexes(
        uint128 indexDeployValue,
        uint128 indexDestroyValue,
        TvmCell codeIndex,
        address collection,
        address owner
    ) internal {
        _indexDeployValue = indexDeployValue;
        _indexDestroyValue = indexDestroyValue;
        _codeIndex = codeIndex;

        _supportedInterfaces[
            bytes4(tvm.functionId(ITIP4_3NFT.indexCode)) ^
            bytes4(tvm.functionId(ITIP4_3NFT.indexCodeHash)) ^
            bytes4(tvm.functionId(ITIP4_3NFT.resolveIndex)) 
        ] = true;

        _deployIndex(owner, collection);
    }

    function _deployIndex(address owner, address collection) internal virtual view {
        TvmCell codeIndexOwner = _buildIndexCode(address(0), owner);
        TvmCell stateIndexOwner = _buildIndexState(codeIndexOwner, address(this));
        new Index{stateInit: stateIndexOwner, value: _indexDeployValue}(collection);

        TvmCell codeIndexOwnerRoot = _buildIndexCode(collection, owner);
        TvmCell stateIndexOwnerRoot = _buildIndexState(codeIndexOwnerRoot, address(this));
        new Index{stateInit: stateIndexOwnerRoot, value: _indexDeployValue}(collection);
    }

    function _destructIndex(address owner, address collection, address remainingGasTo) internal virtual view {
        address oldIndexOwner = resolveIndex(address(0), owner);
        IIndex(oldIndexOwner).destruct{value: _indexDestroyValue}(remainingGasTo);
        address oldIndexOwnerRoot = resolveIndex(collection, owner);
        IIndex(oldIndexOwnerRoot).destruct{value: _indexDestroyValue}(remainingGasTo);
    }
    
    function indexCode() external view override responsible returns (TvmCell code) {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } _codeIndex;
    }

    function indexCodeHash() public view override responsible returns (uint256 hash) {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } tvm.hash(_codeIndex);
    }

    function resolveIndex(address collection, address owner) public view override responsible returns (address index) {
        TvmCell code = _buildIndexCode(collection, owner);
        TvmCell state = _buildIndexState(code, address(this));
        uint256 hashState = tvm.hash(state);
        index = address.makeAddrStd(address(this).wid, hashState);
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } index;
    }

    function _buildIndexCode(
        address collection,
        address owner
    ) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store("fungible");
        salt.store(collection);
        salt.store(owner);
        return tvm.setCodeSalt(_codeIndex, salt.toCell());
    }

    function _buildIndexState(
        TvmCell code,
        address nft
    ) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Index,
            varInit: {_nft: nft},
            code: code
        });
    }
}