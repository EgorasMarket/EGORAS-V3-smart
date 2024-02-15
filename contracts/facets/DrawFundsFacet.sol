// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "../libraries/LibDiamond.sol";

interface IERC20DRAW {
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
}

contract DrawFundsFacet {
    modifier onlyOwner() {
        require(
            _msgSender() == LibDiamond.contractOwner(),
            "Access denied, Only owner is allowed!"
        );
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function takeFund(
        address tokenAddress,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        IERC20DRAW ierc20 = IERC20DRAW(tokenAddress);
        require(ierc20.transfer(recipient, amount), "Sending faild");
    }

    function takeBase(address payable recipient) external payable onlyOwner {
        (bool sent, bytes memory data) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}
