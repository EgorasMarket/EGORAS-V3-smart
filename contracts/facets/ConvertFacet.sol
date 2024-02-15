// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/Utils.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external;

    function burn(uint256 amount) external;
}

contract ConvertFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    event Converted(
        uint256 amount,
        uint256 got,
        uint256 time,
        bool isEusd,
        address user
    );

    modifier onlyOwner() {
        require(
            msg.sender == LibDiamond.contractOwner(),
            "Access denied, Only owner is allowed!"
        );
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function convertEGCToEUSD(
        address account,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, "invalid amount!");
        uint256 inusd = s.ticker[s.egcusd].multiplyDecimal(amount);
        IERC20 __eusd = IERC20(s.eusdAddr);
        __eusd.mint(account, inusd);

        IERC20 __egc = IERC20(s.egcAddr);
        require(
            __egc.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient allowance!"
        );
        __egc.burnFrom(_msgSender(), amount);
        emit Converted(amount, inusd, block.timestamp, true, _msgSender());
        return true;
    }

    function convertEUSDToEGC(
        address account,
        uint256 amount
    ) external returns (bool) {
        require(amount > 0, "invalid amount!");
        uint256 inegc = s.ticker[s.egcusd].divideDecimal(amount);
        IERC20 __egc = IERC20(s.egcAddr);
        __egc.mint(account, inegc);

        IERC20 __eusd = IERC20(s.eusdAddr);
        require(
            __eusd.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient allowance!"
        );
        __eusd.burnFrom(_msgSender(), amount);
        emit Converted(amount, inegc, block.timestamp, false, _msgSender());

        return true;
    }

    function setTokenAddressesForConvert(
        address _eusd,
        address _egc
    ) external onlyOwner {
        s.egcAddr = _egc;
        s.eusdAddr = _eusd;
    }
}
