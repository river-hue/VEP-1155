pragma ton-solidity >= 0.58.0;

import '@broxus/contracts/contracts/libraries/MsgFlag.tsol';

contract MultiTokenWalletPlatform {

    uint256 static _id;
    address static _collection;
    
    address static _owner;

    constructor(TvmCell walletCode, TvmCell params, address sender, address remainingGasTo)
        public
        functionID(0x60903B64)
    {
        if (msg.sender == _collection || (sender.value != 0 && _getExpectedAddress(sender) == msg.sender)) {
           initialize(walletCode, params, remainingGasTo);
        } else {
            remainingGasTo.transfer({
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.DESTROY_IF_ZERO,
                bounce: false
            });
        }
    }

    function _getExpectedAddress(address owner) private view returns (address) {
        TvmCell stateInit = tvm.buildStateInit({
            contr: MultiTokenWalletPlatform,
            varInit: {
                _id: _id,
                _collection: _collection,
                _owner: owner
            },
            pubkey: 0,
            code: tvm.code()
        });

        return address(tvm.hash(stateInit));
    }

    function initialize(TvmCell walletCode, TvmCell params, address remainingGasTo) private {

        TvmCell data = abi.encode(
			_id,
			_collection,
			_owner,
            remainingGasTo,
            params,
            tvm.code()
		);

        tvm.setcode(walletCode);
        tvm.setCurrentCode(walletCode);

        onCodeUpgrade(data);
    }

    function onCodeUpgrade(TvmCell data) private {}
}
