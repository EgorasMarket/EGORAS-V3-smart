// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface ERC20I {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);
}

contract SwapFacet {
    AppStorage internal s;
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;

    event liquidityAdded(address user, uint256 _amount, uint256 time);
    event Swaped(
        address user,
        uint256 _amountGive,
        uint256 _amountGet,
        bool isBase,
        uint256 time
    );
    event Init(
        address __priceOracle,
        address __baseAddress,
        address __tokenAddress,
        string __price,
        uint256 __time
    );

    modifier onlyOwner() {
        require(
            _msgSender() == LibDiamond.contractOwner(),
            "Access denied, Only owner is allowed!"
        );
        _;
    }

    function _tFrom(
        address _contract,
        uint256 _amount,
        address _recipient
    ) internal {
        require(
            ERC20I(_contract).allowance(_msgSender(), _recipient) >= _amount,
            "Non-sufficient funds"
        );
        require(
            ERC20I(_contract).transferFrom(_msgSender(), _recipient, _amount),
            "Fail to tranfer fund"
        );
    }

    function _bFrom(
        address _contract,
        uint256 _amount,
        address _recipient
    ) internal {
        require(
            ERC20I(_contract).allowance(_msgSender(), _recipient) >= _amount,
            "Non-sufficient funds"
        );
        require(
            ERC20I(_contract).burnFrom(_msgSender(), _amount),
            "Fail to burn fund"
        );
    }

    function _mint(
        address _contract,
        uint256 _amount,
        address _recipient
    ) internal {
        require(
            ERC20I(_contract).mint(_recipient, _amount),
            "Fail to tranfer fund"
        );
    }

    function _bOf(address _contract, address _rec)
        internal
        view
        returns (uint256)
    {
        return ERC20I(_contract).balanceOf(_rec);
    }

    function _tr(
        uint256 _amount,
        address _rec,
        address _contract
    ) internal {
        require(
            ERC20I(_contract).transfer(_rec, _amount),
            "Fail to tranfer fund"
        );
    }

    function _getAmount(
        uint256 _marketPrice,
        uint256 _amount,
        bool _isBase
    ) internal pure returns (uint256) {
        return
            _isBase
                ? _amount.divideDecimal(_marketPrice)
                : _amount.multiplyDecimal(_marketPrice);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function swap(uint256 _amount, bool _isBase) external {
        _isBase ? _getBase(_amount) : _getToken(_amount);
    }

    function _getBase(uint256 _amount) internal {
        require(_amount > 0, "Zero value provided!");
        _tFrom(s._tokenAddress, _amount, address(this));
        uint256 _marketPrice = s.ticker[s._price];
        uint256 getAmount = _getAmount(_marketPrice, _amount, false);
        s.userTotalSwap[_msgSender()][false] = s
        .userTotalSwap[_msgSender()][false].add(_amount);
        s.totalSwap[false] = s.totalSwap[false].add(_amount);
        _mint(s._baseAddress, getAmount, _msgSender());
        emit Swaped(_msgSender(), _amount, getAmount, false, block.timestamp);
    }

    function getToken(uint256 _amount) external {
        require(_amount > 0, "Zero value provided!");
        _tFrom(s._baseAddress, _amount, address(this));
        uint256 _marketPrice = s.ticker[s._price];
        uint256 getAmount = _getAmount(_marketPrice, _amount, true);
        s.userTotalSwap[_msgSender()][true] = s
        .userTotalSwap[_msgSender()][true].add(_amount);
        s.totalSwap[true] = s.totalSwap[true].add(_amount);
        _tr(getAmount, _msgSender(), s._tokenAddress);
        emit Swaped(_msgSender(), _amount, getAmount, true, block.timestamp);
    }

    function _getToken(uint256 _amount) internal {
        require(_amount > 0, "Zero value provided!");
        _tFrom(s._baseAddress, _amount, address(this));
        uint256 _marketPrice = s.ticker[s._price];
        uint256 getAmount = _getAmount(_marketPrice, _amount, true);
        s.userTotalSwap[_msgSender()][true] = s
        .userTotalSwap[_msgSender()][true].add(_amount);
        s.totalSwap[true] = s.totalSwap[true].add(_amount);
        _tr(getAmount, _msgSender(), s._tokenAddress);
        emit Swaped(_msgSender(), _amount, getAmount, true, block.timestamp);
    }

    function getUserTotalSwap(address _user)
        external
        view
        returns (uint256 _base, uint256 _token)
    {
        return (s.userTotalSwap[_user][true], s.userTotalSwap[_user][false]);
    }

    function getSystemTotalSwap()
        external
        view
        returns (uint256 _base, uint256 _token)
    {
        return (s.totalSwap[true], s.totalSwap[false]);
    }

    function addLiquidity(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Zero value provided!");
        _tFrom(s._tokenAddress, _amount, address(this));
        emit liquidityAdded(_msgSender(), _amount, block.timestamp);
    }
}
