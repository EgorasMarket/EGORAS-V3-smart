// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";
import "../libraries/Utils.sol";

interface ERC20I {
    function balanceOf(address account) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

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

    event liquidityRemoved(address user, uint256 _amount, uint256 time);
    event liquidityAdded(address user, uint256 _amount, uint256 time);
    event Swaped(
        address user,
        uint256 _amountGive,
        uint256 _amountGet,
        bool isBase,
        uint256 time,
        uint fee
    );
    event Init(
        address __priceOracle,
        address __baseAddress,
        address __tokenAddress,
        string __price,
        uint256 __time
    );

    event NewAsset(
        string _ticker,
        address _token_address,
        uint _fee,
        address _creator,
        uint _time
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

    function _bOf(
        address _contract,
        address _rec
    ) internal view returns (uint256) {
        return ERC20I(_contract).balanceOf(_rec);
    }

    function _tr(uint256 _amount, address _rec, address _contract) internal {
        require(
            ERC20I(_contract).transfer(_rec, _amount),
            "Fail to tranfer fund"
        );
    }

    function listAsset(
        string memory _ticker,
        address _token_address,
        uint _fee
    ) external onlyOwner {
        s.token_address[upper(_ticker)] = _token_address;
        s.fee[upper(_ticker)] = _fee;
        s.isListed[upper(_ticker)] = true;
        emit NewAsset(
            _ticker,
            _token_address,
            _fee,
            _msgSender(),
            block.timestamp
        );
    }

    function delistAsset(string memory _ticker) external onlyOwner {
        s.isListed[upper(_ticker)] = false;
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

    function swapToken(uint256 _amount, string memory _ticker) external {
        _getBase(_amount, _ticker);
    }

    function swapBase(uint256 _amount, string memory _ticker) external {
        _getToken(_amount, _ticker);
    }

    function _getBase(uint256 _amount, string memory _ticker) internal {
        require(_amount > 0, "Zero value provided!");
        _tFrom(s.token_address[upper(_ticker)], _amount, address(this));
        uint256 _marketPrice = s.ticker[upper(_ticker)];
        uint256 getAmount = _getAmount(_marketPrice, _amount, false);
        s.userTotalSwap[_msgSender()][false] = s
        .userTotalSwap[_msgSender()][false].add(_amount);
        s.totalSwap[false] = s.totalSwap[false].add(_amount);
        if (s.member[_msgSender()]) {
            _mint(Utils.BASE, getAmount, _msgSender());
            emit Swaped(
                _msgSender(),
                _amount,
                getAmount,
                false,
                block.timestamp,
                0
            );
        } else {
            uint fee = getAmount.multiplyDecimal(Utils.NONE_MEMBER_FEE);
            _mint(Utils.BASE, getAmount.sub(fee), _msgSender());
            emit Swaped(
                _msgSender(),
                _amount,
                getAmount.sub(fee),
                false,
                block.timestamp,
                fee
            );
        }
    }

    function _getToken(uint256 _amount, string memory _ticker) internal {
        require(_amount > 0, "Zero value provided!");
        _bFrom(Utils.BASE, _amount, address(this));
        uint256 _marketPrice = s.ticker[upper(_ticker)];
        uint256 getAmount = _getAmount(_marketPrice, _amount, true);
        s.userTotalSwap[_msgSender()][true] = s
        .userTotalSwap[_msgSender()][true].add(_amount);
        s.totalSwap[true] = s.totalSwap[true].add(_amount);

        if (s.member[_msgSender()]) {
            _tr(getAmount, _msgSender(), s.token_address[upper(_ticker)]);
            emit Swaped(
                _msgSender(),
                _amount,
                getAmount,
                true,
                block.timestamp,
                0
            );
        } else {
            uint fee = getAmount.multiplyDecimal(Utils.NONE_MEMBER_FEE);
            _tr(
                getAmount.sub(fee),
                _msgSender(),
                s.token_address[upper(_ticker)]
            );
            emit Swaped(
                _msgSender(),
                _amount,
                getAmount.sub(fee),
                true,
                block.timestamp,
                fee
            );
        }
    }

    function getUserTotalSwap(
        address _user
    ) external view returns (uint256 _base, uint256 _token) {
        return (s.userTotalSwap[_user][true], s.userTotalSwap[_user][false]);
    }

    function getSystemTotalSwap()
        external
        view
        returns (uint256 _base, uint256 _token)
    {
        return (s.totalSwap[true], s.totalSwap[false]);
    }

    function addLiquidity(uint256 _amount, string memory _ticker) external {
        require(_amount > 0, "Zero value provided!");
        uint256 _marketPrice = s.ticker[upper(_ticker)];
        s.liquidity[upper(_ticker)][_msgSender()] = s
        .liquidity[upper(_ticker)][_msgSender()].add(
                _marketPrice.multiplyDecimal(_amount)
            );
        _tFrom(s.token_address[upper(_ticker)], _amount, address(this));
        emit liquidityAdded(_msgSender(), _amount, block.timestamp);
    }

    function viewLiquidity(
        address _user,
        string memory _ticker
    ) external view returns (uint) {
        return s.liquidity[upper(_ticker)][_user];
    }

    function rmoveLiquidity(string memory _ticker) external {
        uint liquidity = s.liquidity[upper(_ticker)][_msgSender()];
        _mint(Utils.BASE, liquidity, _msgSender());
        emit liquidityRemoved(_msgSender(), liquidity, block.timestamp);
    }

    function upper(string memory _base) internal pure returns (bytes memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return bytes(_baseBytes);
    }

    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }
}
