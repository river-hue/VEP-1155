pragma ton-solidity >= 0.58.0;

interface IMultiTokenCollection {

    /// @notice This event emits when MultiToken is created
    /// @param id Unique MultiToken id
    /// @param token Address of MultiToken wallet contract
    /// @param owner Address of MultiToken wallet owner
    /// @param balance count of minted tokens
    /// @param creator Address of creator that initialize mint
    event MultiTokenCreated(uint256 id, address token, uint128 balance, address owner, address creator);

    /// @notice This event emits when MultiTokens are burned
    /// @param id Unique MultiToken id
    /// @param count Number of burned tokens
    /// @param owner Address of MultiToken wallet owner
    event MultiTokenBurned(uint256 id, uint128 count, address owner);    

    /// @notice Returns the MultiToken wallet code
    /// @return code Returns the MultiToken wallet code as TvmCell
    function multiTokenWalletCode(uint256 id, bool isEmpty) external view responsible returns (TvmCell code);

    /// @notice Returns the MultiToken wallet code hash
    /// @return codeHash Returns the MultiToken wallet code hash
    function multiTokenCodeHash(uint256 id, bool isEmpty) external view responsible returns (uint256 codeHash);

    /// @notice Computes MultiToken wallet address by unique MultiToken id and its owner
    /// @dev Return unique address for all Ids and owners. You find nothing by address for not a valid MultiToken wallet
    /// @param id Unique MultiToken id
    /// @param owner Address of MultiToken owner
    /// @return token Returns the address of MultiToken wallet contract
    function multiTokenWalletAddress(uint256 id, address owner) external view responsible returns (address token);
}