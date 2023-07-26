pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import '../modules/TIP4_2/interfaces/ITIP4_2JSON_Metadata.sol';
import '../modules/TIP6/TIP6.sol';

import '@broxus/contracts/contracts/libraries/MsgFlag.tsol';

abstract contract TIP4_2JSON_Metadata is ITIP4_2JSON_Metadata, TIP6 {
    /// JSON metadata
    /// In order to fill in this field correctly, see https://docs.everscale.network/standard/TIP-4.2
    string _json;

    function _initJson(string json) internal {
        _json = json;

        _supportedInterfaces[
            bytes4(tvm.functionId(ITIP4_2JSON_Metadata.getJson))
        ] = true;
    }
    
    /// See interfaces/ITIP4_2JSON_Metadata.sol
    function getJson() external virtual override view responsible returns (string json) {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } _json;
    }
}