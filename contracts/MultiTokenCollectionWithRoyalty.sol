pragma ton-solidity >= 0.58.0;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './modules/access/OwnableInternal.sol';

import "./abstract/MultiTokenCollectionBase.sol";
import "./abstract/NFTCollectionBase.sol";

import "./MultiTokenWalletPlatform.sol";
import "./NftWithRoyalty.sol";

import "./errors/TokenErrors.sol";
import "./libraries/TokenGas.sol";
import './libraries/MsgFlag.sol';

contract MultiTokenCollectionWithRoyalty is
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
        address royaltyAddress,
        uint128 royalty,
        address remainingGasTo
    ) external internalMsg onlyOwner responsible returns(uint256, address){
        uint256 tokenId = _beforeMint(nftOwner);

        TvmCell codeNft = _buildNftCode(address(this));
        TvmCell stateNft = _buildNftState(codeNft, tokenId);
        address nftAddr = new NftWithRoyalty{
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
            royaltyAddress,
            royalty
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
        address royaltyAddress,
        uint128 royalty,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    ) external internalMsg onlyOwner responsible returns(uint256, address) {

        uint256 tokenId = _beforeMint(tokenOwner);
        _tokenSupply[tokenId] += count;

        TvmCell tokenCode = _buildTokenCode(address(this));
        TvmCell tokenState = _buildTokenState(tokenId, tokenOwner);

        TvmCell params = abi.encode(
			count,
            uint128(TokenGas.TARGET_TOKEN_BALANCE),
            json,
            uint128(NftGas.INDEX_DEPLOY_VALUE),
            uint128(NftGas.INDEX_DESTROY_VALUE),
            _codeIndex,
            royaltyAddress,
            royalty,
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
        
        return { value: 0, bounce: false, flag: MsgFlag.ALL_NOT_RESERVED } (tokenId, tokenAddr);
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
            contr: NftWithRoyalty,
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