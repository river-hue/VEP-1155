pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "./MultiTokenWalletDestroyable.sol";

import "../MultiTokenWalletPlatform.sol";

abstract contract MultiTokenWalletWithDeployRetry is 
    MultiTokenWalletDestroyable
{

    TvmCell _platformCode;

    /*
        0x60903B64 is TokenWalletPlatform constructor functionID
    */
    function onDeployRetry(TvmCell , TvmCell , address sender, address remainingGasTo)
        external
        view
        functionID(0x60903B64)
    {
        require(msg.sender == _collection || address(tvm.hash(_buildTokenState(sender))) == msg.sender);

        tvm.rawReserve(0, 4);

        if (remainingGasTo.value != 0 && remainingGasTo != address(this)) {
            remainingGasTo.transfer({
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            });
        }
    }

    function _buildTokenState(address owner) internal override view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: MultiTokenWalletPlatform,
            varInit: {
                _id: _id,
                _collection: _collection,
                _owner: owner
            },
            pubkey: 0,
            code: _platformCode
        });
    }
}