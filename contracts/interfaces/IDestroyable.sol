pragma ton-solidity >= 0.58.0;

interface IDestroyable {
    function destroy(address remainingGasTo) external;
}
