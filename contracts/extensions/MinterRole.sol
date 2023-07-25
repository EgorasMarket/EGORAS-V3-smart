// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "../utils/Context.sol";
import "../libraries/Role.sol";

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor() {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(
            this.isMinter(_msgSender()),
            "MinterRole: caller does not have the Minter role"
        );
        _;
    }

    function isMinter(address account) external view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) external onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() external {
        _removeMinter(_msgSender());
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}
