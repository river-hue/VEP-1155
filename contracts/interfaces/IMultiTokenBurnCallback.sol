pragma ton-solidity >= 0.58.0;

interface IMultiTokenBurnCallback {

    /// @notice Callback from token contract on burn tokens
    /// @param collection Address of collection smart contract that mint the token
    /// @param tokenId Unique token id
    /// @param count Burned tokens count
    /// @param token Address of token contract that burns tokens
    /// @param remainingGasTo Address specified for receive remaining gas
    /// @param payload Additional data attached to transfer by sender        
    function onMultiTokenBurn(
        address collection,
        uint256 tokenId,
        uint128 count,
        address owner,
        address token,
        address remainingGasTo,
        TvmCell payload
    ) external;
}
