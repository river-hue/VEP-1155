pragma ton-solidity >= 0.58.0;

interface IMultiTokenNft {
    /// @notice Count MultiToken supply
    /// @return count Number of active MultiTokens minted to this nft
    function multiTokenSupply() external view responsible returns (uint128 count);
}