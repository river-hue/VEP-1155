pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "../interfaces/IMultiTokenWallet.sol";
import "../modules/TIP6/TIP6.sol";

import "../interfaces/IMultiTokenBounceTransferCallback.sol";
import "../interfaces/IMultiTokenTransferCallback.sol";
import "../interfaces/IMultiTokenAcceptBurnCallback.sol";
import "../interfaces/IMultiTokenMintCallback.sol";


import "../errors/TokenErrors.sol";
import "@broxus/contracts/contracts/libraries/MsgFlag.tsol";

abstract contract MultiTokenWalletBase is IMultiTokenWallet, TIP6 {

    uint256 _id;
    address _collection;
    address _owner;
    address _nft;

    uint128 _balance;

    modifier onlyOwner virtual {
        require(msg.sender == _owner, TokenErrors.SEND_NOT_TOKEN_OWNER);
        _;
    }

    function _initWalletBase(
        address owner,
        address collection,
        address nft,
        uint256 id,
        uint128 balance,
        uint128 remainOnNft,
        bool notify,
        TvmCell payload,
        address remainingGasTo
    ) internal {
        require(balance == 0 || msg.sender == collection, TokenErrors.SENDER_NOT_COLLECTION);
        require(remainOnNft != 0, TokenErrors.EMPTY_VALUE);
        require(msg.value > remainOnNft, TokenErrors.VALUE_TOO_LOW);
        tvm.rawReserve(remainOnNft, 0);

        _id = id;
        _collection = collection;
        _nft = nft;

        _owner = owner;
        _balance = balance;

        _supportedInterfaces[ bytes4(tvm.functionId(ITIP6.supportsInterface)) ] = true;
        _supportedInterfaces[
            bytes4(tvm.functionId(IMultiTokenWallet.getInfo)) ^
            bytes4(tvm.functionId(IMultiTokenWallet.balance)) ^
            bytes4(tvm.functionId(IMultiTokenWallet.transfer)) ^
            bytes4(tvm.functionId(IMultiTokenWallet.transferToWallet)) ^
            bytes4(tvm.functionId(IMultiTokenWallet.acceptTransfer)) ^
            bytes4(tvm.functionId(IMultiTokenWallet.burn)) 
        ] = true;

        emit MultiTokenWalletCreated(_id, _owner, collection, balance);

        if (notify && balance > 0) {
            IMultiTokenMintCallback(_owner).onMintMultiToken{
                value: 0,
                bounce: false,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS
            }(
                _collection,
                _id,
                balance,
                remainingGasTo,
                payload
            );
        } if (remainingGasTo.value != 0 && remainingGasTo != address(this)) {
            remainingGasTo.transfer({
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            });
        }
    }

    function getInfo() external virtual override view responsible returns(uint256 id, address owner, address collection)
    {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } (_id, _owner, _collection);
    }

    function balance() external virtual override view responsible returns (uint128 value)
    {
        return { value: 0, flag: MsgFlag.REMAINING_GAS, bounce: false } _balance;
    }

    function transfer(
        uint128 count,
        address recipient,
        uint128 deployTokenWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    ) 
        virtual override
        external
        onlyOwner
    {
        require(count > 0, TokenErrors.WRONG_COUNT);
        require(count <= _balance, TokenErrors.NOT_ENOUGH_BALANCE);
        require(recipient.value != 0 && recipient != _owner, TokenErrors.WRONG_RECIPIENT);

        tvm.rawReserve(0, 4);

        TvmCell tokenState = _buildTokenState(recipient);

        address recipientToken;

        if (deployTokenWalletValue > 0) {
            recipientToken = _deployToken(tokenState, deployTokenWalletValue, remainingGasTo);
        } else {
            recipientToken = address(tvm.hash(tokenState));
        }
            
        _balance -= count;

        _afterTokenTransfer(count, recipient, remainingGasTo);

        IMultiTokenWallet(recipientToken).acceptTransfer{ value: 0, flag: MsgFlag.ALL_NOT_RESERVED, bounce: true }(
            count,
            _owner,
            remainingGasTo,
            notify,
            payload
        );
    }

    function transferToWallet(
        uint128 count,
        address recipientToken,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )
        virtual override
        external
        onlyOwner
    {
        require(count > 0, TokenErrors.WRONG_COUNT);
        require(count <= _balance, TokenErrors.NOT_ENOUGH_BALANCE);
        require(recipientToken.value != 0 && recipientToken != address(this), TokenErrors.WRONG_RECIPIENT);

        tvm.rawReserve(0, 4);

        _balance -= count;

        _afterTokenTransfer(count, recipientToken, remainingGasTo);

        IMultiTokenWallet(recipientToken).acceptTransfer{ value: 0, flag: MsgFlag.ALL_NOT_RESERVED, bounce: true }(
            count,
            _owner,
            remainingGasTo,
            notify,
            payload
        );
    }
    
    function acceptTransfer(
        uint128 count,
        address sender,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )
        virtual override
        external
    {
        require(msg.sender == address(tvm.hash(_buildTokenState(sender))), TokenErrors.SENDER_IS_NOT_VALID_TOKEN);

        tvm.rawReserve(0, 4);

        _balance += count;

        _afterTokenTransfer(count, _owner, remainingGasTo);
        
        emit MultiTokenTransfered(sender, msg.sender, _owner, count, _balance);

        if (notify) {
            IMultiTokenTransferCallback(_owner).onMultiTokenTransfer{
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            }(
                _collection,
                _id,
                count,
                sender,
                msg.sender,
                remainingGasTo,
                payload
            );
        } else {
            remainingGasTo.transfer({ value: 0, flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS, bounce: false });
        }
    }

    function burn(
        uint128 count,
        address remainingGasTo,
        address callbackTo,
        TvmCell payload
    )
        virtual override
        external
        onlyOwner
    {
        require(count > 0, TokenErrors.WRONG_COUNT);
        require(count <= _balance, TokenErrors.NOT_ENOUGH_BALANCE);

        tvm.rawReserve(0, 4);

        _balance -= count;
        _afterTokenBurn(count, remainingGasTo);
        
        IMultiTokenAcceptBurnCallback(_collection).onAcceptMultiTokensBurn{
            value: 0,
            flag: MsgFlag.ALL_NOT_RESERVED,
            bounce: true
        }(
            count,
            _id,
            _owner,
            remainingGasTo,
            callbackTo,
            payload
        );
    }

    /// @notice On-bounce handler
    /// @dev Catch bounce if acceptTransfer or onTokenBurned fails
    /// @dev If transfer fails - increase back tokens balance and notify owner
    /// @dev If tokens burn collection token callback fails - increase back tokens balance and notify owner
    onBounce(TvmSlice body) virtual external {
        tvm.rawReserve(0, 4);

        uint32 functionId = body.decode(uint32);

        if (functionId == tvm.functionId(IMultiTokenWallet.acceptTransfer)) {
            uint128 count = body.decode(uint128);
            _balance += count;
            _afterTokenTransferBounce(count, msg.sender);
            IMultiTokenBounceTransferCallback(_owner).onMultiTokenBounceTransfer{
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            }(
                _collection,
                _id,
                count,
                msg.sender
            );
        }
    }

    /// @notice Generates a StateInit from owner
    /// @param owner Owner contract address
    /// @return TvmCell object - stateInit
    /// about tvm.buildStateInit read more here (https://github.com/tonlabs/TON-Solidity-Compiler/blob/master/API.md#tvmbuildstateinit)
    function _buildTokenState(address owner) internal virtual view returns (TvmCell);

    function _deployToken(TvmCell tokenState, uint128 deployWalletValue, address remainingGasTo) virtual internal view returns (address);
    function _afterTokenTransfer(uint128 count, address recipient, address remainingGasTo) virtual internal;
    function _afterTokenBurn(uint128 count, address remainingGasTo) virtual internal;
    function _afterTokenTransferBounce(uint128 count, address recipient) virtual internal;
}