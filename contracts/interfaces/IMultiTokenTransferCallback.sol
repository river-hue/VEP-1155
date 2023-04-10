pragma ton-solidity >= 0.58.0;

interface IMultiTokenTransferCallback {

    /// @notice Callback from token contract on receive tokens transfer
    /// @param collection Address of collection smart contract that mint the token
    /// @param tokenId Unique token id
    /// @param count Received tokens count
    /// @param sender Sender TokenWallet owner address
    /// @param senderToken Sender TokenWallet address
    /// @param remainingGasTo Address specified for receive remaining gas
    /// @param payload Additional data attached to transfer by sender        
    function onMultiTokenTransfer(
        address collection,
        uint256 tokenId,
        uint128 count,
        address sender,
        address senderToken,
        address remainingGasTo,
        TvmCell payload
    ) external;
}
