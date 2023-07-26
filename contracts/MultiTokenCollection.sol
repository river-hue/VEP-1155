pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './modules/access/OwnableInternal.sol';

import "./abstract/MultiTokenCollectionBase.sol";
import "./abstract/NFTCollectionBase.sol";

import "./MultiTokenWalletPlatform.sol";
import "./Nft.sol";

import "./errors/TokenErrors.sol";
import "./libraries/TokenGas.sol";
import '@broxus/contracts/contracts/libraries/MsgFlag.tsol';

contract MultiTokenCollection is
   OwnableInternal,
   NFTCollectionBase,
   MultiTokenCollectionBase
{
    address static _deployer;
   	uint64 static _nonce;

    TvmCell static _platformCode;

    uint128 _lastTokenId;

    constructor(
        TvmCell codeNft,
        TvmCell codeToken,
        TvmCell codeIndex,
        TvmCell codeIndexBasis,
        address ownerAddress,
        string json,
        address remainingGasTo
    ) OwnableInternal(
        ownerAddress
    ) NFTCollectionBase (
        codeNft,
        codeIndex,
        codeIndexBasis,
        json
    ) MultiTokenCollectionBase (
        codeToken,
        remainingGasTo
    ) public {
        if (msg.pubkey() != 0) {
            require(msg.pubkey() == tvm.pubkey() && _deployer.value == 0, TokenErrors.NOT_DEPLOYER);
            tvm.accept();
        } else {
            require(_deployer.value != 0 && msg.sender == _deployer, TokenErrors.NOT_DEPLOYER);
        }
    }

    function mintNft(
        address nftOwner,
        string json,
        address remainingGasTo
    ) external internalMsg onlyOwner responsible returns(uint256, address){
        uint256 tokenId = _beforeMint(nftOwner);

        TvmCell codeNft = _buildNftCode(address(this));
        TvmCell stateNft = _buildNftState(codeNft, tokenId);
        address nftAddr = new Nft{
            stateInit: stateNft,
            value: NftGas.NFT_DEPLOY_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES
        }(
            nftOwner,
            remainingGasTo,
            NftGas.TARGET_NFT_BALANCE,
            json,
            NftGas.INDEX_DEPLOY_VALUE,
            NftGas.INDEX_DESTROY_VALUE,
            _codeIndex,
            uint128(0)
        ); 

        emit NftCreated(
            tokenId, 
            nftAddr,
            nftOwner,
            nftOwner, 
            msg.sender
        );
        
        return { value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED } (tokenId, nftAddr);
    }

    function mintToken(
        address tokenOwner,
        string json,
        uint128 count,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    ) external internalMsg onlyOwner responsible returns(uint256, address, address) {

        uint256 tokenId = _beforeMint(tokenOwner);
        
        TvmCell codeNft = _buildNftCode(address(this));
        TvmCell stateNft = _buildNftState(codeNft, tokenId);
        address nftAddr = new Nft{
            stateInit: stateNft,
            value: NftGas.NFT_DEPLOY_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES
        }(
            address(this),
            remainingGasTo,
            NftGas.TARGET_NFT_BALANCE,
            json,
            NftGas.INDEX_DEPLOY_VALUE,
            NftGas.INDEX_DESTROY_VALUE,
            _codeIndex,
            count
        ); 

        emit NftCreated(
            tokenId, 
            nftAddr,
            address(this),
            address(this), 
            msg.sender
        );

        TvmCell tokenCode = _buildTokenCode(address(this), tokenId, false);
        TvmCell tokenState = _buildTokenState(tokenId, tokenOwner);

        TvmCell params = abi.encode(
            nftAddr,
			count,
            uint128(TokenGas.TARGET_TOKEN_BALANCE),
            uint128(NftGas.INDEX_DEPLOY_VALUE),
            uint128(NftGas.INDEX_DESTROY_VALUE),
            _codeIndex,
            notify,
            payload
		);

        address tokenAddr = new MultiTokenWalletPlatform {
            stateInit: tokenState,
            value: TokenGas.TOKEN_DEPLOY_VALUE,
            flag: MsgFlag.SENDER_PAYS_FEES
        }(tokenCode, params, tokenOwner, remainingGasTo);

        emit MultiTokenCreated(
            tokenId, 
            tokenAddr,
            count,
            tokenOwner,
            msg.sender
        );
        
        return { value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED } (tokenId, tokenAddr, nftAddr);
    }

function onAcceptMultiTokensBurn(
        uint128 count,
        uint256 id,
        address owner,
        address remainingGasTo,
        address callbackTo,
        TvmCell payload
    ) external internalMsg virtual override {
        require(msg.sender == _resolveToken(id, owner));
        tvm.rawReserve(_reserve(), 0);

        address nft = _resolveNft(id);

        TvmCell params = abi.encode(count, id, owner, remainingGasTo, callbackTo, payload);

        IMultiTokenNftBurn(nft).burnToken{
            callback: MultiTokenCollection.onTokenSupplyUpdate, value: 0, flag: MsgFlag.ALL_NOT_RESERVED
            }(count, id, owner, params);
        
    }

    function onTokenSupplyUpdate(uint128 tokenSupply, TvmCell params) external {
        (uint128 count,
        uint256 id,
        address owner,
        address remainingGasTo,
        address callbackTo,
        TvmCell payload) = abi.decode(params, (uint128, uint256, address, address, address, TvmCell));
        require(msg.sender == _resolveNft(id));

        if (tokenSupply == 0) {
            _decreaseTotalSupply();
        }

        emit MultiTokenBurned(id, count, owner);

        if (callbackTo.value == 0) {
            remainingGasTo.transfer({
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            });
        } else {
            IMultiTokenBurnCallback(callbackTo).onMultiTokenBurn{
                value: 0,
                flag: MsgFlag.ALL_NOT_RESERVED + MsgFlag.IGNORE_ERRORS,
                bounce: false
            }(
                address(this),
                id,
                count,
                owner,
                msg.sender,
                remainingGasTo,
                payload
            );
        }
    }

    function _beforeMint(address mintFor) internal returns (uint256) {
        require(mintFor.value != 0, TokenErrors.NO_OWNER);

        tvm.rawReserve(_reserve(), 0);

        uint256 tokenId = _lastTokenId;

        _totalSupply++;
        _lastTokenId++;

        return tokenId;
    }
    
    function _buildNftState(
        TvmCell code,
        uint256 id
    ) internal virtual override pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Nft,
            varInit: {_id: id},
            code: code
        });
    }

    function _buildTokenState(
        uint256 id,
        address owner
    ) internal virtual override(MultiTokenCollectionBase) view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: MultiTokenWalletPlatform,
            varInit: {
                _id: id,
                _collection: address(this),
                _owner: owner
            },
            pubkey: 0,
            code: _platformCode
        });
    }

    function _decreaseTotalSupply() internal override virtual {
        _totalSupply--;
    }

    function _targetBalance() override internal pure returns (uint128) {
        return NftGas.TARGET_COLLECTION_BALANCE;
    }

    function _isOwner() internal override onlyOwner returns(bool){
        return true;
    }
}