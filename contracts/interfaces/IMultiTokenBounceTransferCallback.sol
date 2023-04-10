pragma ton-solidity >= 0.58.0;

interface IMultiTokenBounceTransferCallback {

    /// @notice Callback from TokenWallet when tokens transfer reverted
    /// @param collection Collection of received tokens
    /// @param tokenId Unique token id
    /// @param count Reverted tokens count
    /// @param revertedFrom Address which declained acceptTransfer
    function onMultiTokenBounceTransfer(
        address collection,
        uint256 tokenId,
        uint128 count,
        address revertedFrom
    ) external;
}
