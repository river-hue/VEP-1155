pragma ton-solidity >= 0.58.0;

interface IMultiTokenWallet {

    /// @notice The event emits when MultiToken is created
    /// @dev Emit the event when MultiToken is ready to use
    /// @param id Unique MultiToken id
    /// @param owner Address of MultiToken owner
    /// @param collection Address of collection smart contract that mint the MultiToken
    /// @param balance count of minted tokens
    event MultiTokenWalletCreated(uint256 id, address owner, address collection, uint128 balance);

    /// @notice The event emits when MultiToken is transfered
    /// @dev Emit the event when token is ready to use
    /// @param sender MultiToken wallet owner address that sends MultiTokens
    /// @param senderWallet Sender MultiToken wallet address
    /// @param recipient Address of owner of recipient MultiToken wallet contract
    /// @param count How many MultiTokens transfered
    /// @param newBalance Recipient wallet balance after transfer
    event MultiTokenTransfered(address sender, address senderWallet, address recipient, uint128 count, uint128 newBalance);

    /// @notice MultiToken info
    /// @return id Unique MultiToken id
    /// @return owner Address of wallet owner
    /// @return collection Сollection smart contract address
    function getInfo() external view responsible returns(uint256 id, address owner, address collection);

    /// @notice Returns the number of owned MultiTokens
    /// @return value owned MultiTokens count
    function balance() external view responsible returns (uint128 value);
    
    /// @notice Transfer MultiTokens to the recipient
    /// @dev Can be called only by MultiToken owner
    /// @param count How many MultiTokens to transfer
    /// @param recipient Address of owner of recipient MultiToken wallet contract
    /// @param deployTokenWalletValue How much Venom send to MultiToken wallet contract on deployment. Do not deploy contract if zero.
    /// @param remainingGasTo Remaining gas receiver
    /// @param notify Notify receiver on incoming transfer
    /// @param payload Notification payload
    function transfer(uint128 count, address recipient, uint128 deployTokenWalletValue, address remainingGasTo, bool notify, TvmCell payload) external;

    /// @notice Transfer MultiTokens to the MultiToken wallet contract
    /// @dev Can be called only by MultiToken owner
    /// @param count How many MultiTokens to transfer
    /// @param recipientToken Recipient MultiToken wallet contract address
    /// @param remainingGasTo Remaining gas receiver
    /// @param notify Notify receiver on incoming transfer
    /// @param payload Notification payload
    function transferToWallet(uint128 count, address recipientToken, address remainingGasTo, bool notify, TvmCell payload) external;

    /// @notice Callback for transfer operation
    /// @dev Can be called only by another valid MultiToken wallet contract with same id and collection
    /// @param count How many MultiTokens to receiver
    /// @param sender MultiToken wallet owner address that sends MultiTokens
    /// @param remainingGasTo Remaining gas receiver
    /// @param notify Notify receiver on incoming transfer
    /// @param payload Notification payload
    function acceptTransfer(uint128 count, address sender, address remainingGasTo, bool notify, TvmCell payload) external;

    /// @notice Burn MultiTokens by owner
    /// @dev Can be called only by MultiToken owner
    /// @param count How many MultiTokens to burn
    /// @param remainingGasTo Remaining gas receiver
    /// @param callbackTo Burn callback address
    /// @param payload Notification payload
    function burn(uint128 count, address remainingGasTo, address callbackTo, TvmCell payload) external;
}