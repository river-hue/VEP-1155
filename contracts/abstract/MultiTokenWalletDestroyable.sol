pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./MultiTokenWalletBase.sol";
import "./TIP4_2JSON_Metadata.sol";
import "./TIP4_3NFT.sol";

import "../interfaces/IDestroyable.sol";

abstract contract MultiTokenWalletDestroyable is 
    MultiTokenWalletBase,
    TIP4_3NFT,
    IDestroyable
{
    function _initWalletDestroyable() internal {
        _supportedInterfaces[bytes4(tvm.functionId(IDestroyable.destroy))] = true;       
    }

    function _afterTokenTransfer(uint128 count, address recipient, address remainingGasTo) virtual override internal {
        if (_balance == 0) { _destructIndex(_owner, _collection, remainingGasTo); _destroySalt(); }
        if (_balance == count && recipient.value == _owner.value) { _deployIndex(_owner, _collection); _restoreSalt(); }
    }

    function _afterTokenBurn(uint128 count, address remainingGasTo) virtual override internal {
        if (_balance == 0) {
            _destructIndex(_owner, _collection, remainingGasTo);
            _destroySalt();
        }
    }

    function _afterTokenTransferBounce(uint128 count, address recipient) virtual override internal {
        if (_balance == count) {
            _deployIndex(_owner, _collection);
            _restoreSalt();
        }
    }

    function destroy(address remainingGasTo) virtual override external onlyOwner {
        require(_balance == 0, TokenErrors.NON_EMPTY_BALANCE);

        _destructIndex(_owner, _collection, remainingGasTo);
        selfdestruct(remainingGasTo);
    }

    function _destroySalt() internal {
        TvmCell emptySaltCode = tvm.setCodeSalt(tvm.code(), abi.encode(address(0)));
        tvm.setcode(emptySaltCode);
        tvm.setCurrentCode(emptySaltCode);
    }

    function _restoreSalt() internal {
        TvmCell restoredSaltCode = tvm.setCodeSalt(tvm.code(), abi.encode(_collection));
        tvm.setcode(restoredSaltCode);
        tvm.setCurrentCode(restoredSaltCode);
    }
}