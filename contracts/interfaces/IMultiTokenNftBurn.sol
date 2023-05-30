pragma ton-solidity >= 0.58.0;

interface IMultiTokenNftBurn {

    function burnToken(
        uint128 count,
        uint256 id,
        address owner,
        TvmCell payload
    ) external responsible returns (uint128 tokenSupply, TvmCell next);
    
}