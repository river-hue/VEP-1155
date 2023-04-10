pragma ton-solidity >= 0.58.0;

interface IMultiTokenAcceptBurnCallback {
    function onAcceptMultiTokensBurn(
        uint128 count,
        uint256 id,
        address owner,
        address remainingGasTo,
        address callbackTo,
        TvmCell payload
    ) external internalMsg;
}