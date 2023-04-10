pragma ton-solidity >= 0.61.2;

/// @title This extension is used to add the owner role to the contract. It is used to manage contracts through internal messages.
abstract contract OwnableInternal {
    
    /// Owner address (0:...)
    address private _owner;

    event OwnershipTransferred(address oldOwner, address newOwner);

    constructor (address owner) public {
        _transferOwnership(owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner.value != 0, 100);
        tvm.rawReserve(0, 4);
        _transferOwnership(newOwner);
        // flags ALL_NOT_RESERVED+IGNORE_ERRORS
        msg.sender.transfer({ value: 0, flag: 128+2, bounce: false });
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    modifier onlyOwner() virtual {
        require(msg.sender.value != 0 && owner() == msg.sender, 100);
        require(msg.value != 0, 101);
        _;
    }

}