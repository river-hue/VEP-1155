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
    TIP4_2JSON_Metadata,
    TIP4_3NFT,
    IDestroyable
{
    function _initWalletDestroyable() internal {
        _supportedInterfaces[bytes4(tvm.functionId(IDestroyable.destroy))] = true;       
    }

    function destroy(address remainingGasTo) virtual override external onlyOwner {
        require(_balance == 0, TokenErrors.NON_EMPTY_BALANCE);

        _destructIndex(_owner, _collection, remainingGasTo);
        selfdestruct(remainingGasTo);
    }
}