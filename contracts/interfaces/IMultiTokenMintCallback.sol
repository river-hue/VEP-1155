pragma ton-solidity >= 0.58.0;

interface IMultiTokenMintCallback {

    /// @notice Callback from token contract on mint initial token
    /// @param collection Address of collection smart contract that mint the token
    /// @param tokenId Unique token id
    /// @param count Minted tokens count
    /// @param remainingGasTo Address specified for receive remaining gas
    /// @param payload Additional data attached to transfer by sender
    function onMintMultiToken(
        address collection,
        uint256 tokenId,
        uint128 count,
        address remainingGasTo,
        TvmCell payload
    ) external;
}
