pragma ton-solidity >= 0.58.0;

interface INFTAcceptBurnCallback {
    function onAcceptNFTBurn(uint256 id, address owner, address manager) external internalMsg;
}