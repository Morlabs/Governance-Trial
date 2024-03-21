// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Proxy {
    address private _admin;
    address private _implementation;

    event Upgraded(address indexed newImplementation);

    constructor(address initialImplementation, address initialAdmin) {
        _implementation = initialImplementation;
        _admin = initialAdmin;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "Proxy: caller is not the admin");
        _;
    }

    function upgradeTo(address newImplementation) external onlyAdmin {
        _implementation = newImplementation;
        emit Upgraded(newImplementation);
    }

    function implementation() public view returns (address) {
        return _implementation;
    }

    function admin() public view returns (address) {
        return _admin;
    }

    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Proxy: new admin is the zero address");
        _admin = newAdmin;
    }

    receive() external payable {}

    fallback() external {
        address _impl = implementation();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}
