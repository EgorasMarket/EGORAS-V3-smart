// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface Ora {
    function price(string memory _ticker) external view returns (uint);
}

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

contract ExFacet {
    AppStorage internal s;
    using SafeDecimalMath for uint256;
    using SafeMath for uint256;
    mapping(bytes => address) base_address;
    mapping(bytes => address) token_address;

    mapping(address => mapping(bytes => mapping(bool => uint256))) userTotalSwap;

    mapping(bytes => mapping(bool => uint256)) totalSwap;
    uint256 ex_fee;
    mapping(bytes => uint256) base_fee;
    mapping(bytes => uint256) token_fee;
    mapping(bytes => uint256) base_liquidity;
    mapping(bytes => uint256) token_liquidity;
    mapping(bytes => mapping(address => uint)) userBaseliquidity;
    mapping(bytes => mapping(address => uint)) userTokenliquidity;
    mapping(bytes => bool) isListed;
    event Swaped(
        address user,
        uint256 _amountGive,
        uint256 _amountGet,
        bool isBase,
        uint256 time,
        uint fee,
        string ticker
    );

    event NewAsset(
        string _ticker,
        address _token_address,
        address _base_address,
        address _creator,
        uint _time
    );

    event liquidityAdded(
        address user,
        uint256 _baseAmount,
        uint256 _tokenAmount,
        string _ticker,
        uint256 time
    );

    event liquidityRemoved(
        address user,
        uint256 _baseAmount,
        uint256 _tokenAmount,
        string _ticker,
        uint256 time
    );

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

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

    function _getAmountEx(
        uint256 _marketPrice,
        uint256 _amount,
        bool _isBase
    ) internal pure returns (uint256) {
        return
            _isBase
                ? _amount.divideDecimal(_marketPrice)
                : _amount.multiplyDecimal(_marketPrice);
    }

    function getBaseEx(uint256 _amount, string memory _ticker) external {
        Ora _ora = Ora(address(this));
        require(isListed[upper(_ticker)], "Invalid Pair");
        require(_amount > 0, "Zero value provided!");
        _tFrom(token_address[upper(_ticker)], _amount, address(this));
        uint256 _marketPrice = _ora.price(_ticker);
        uint256 getAmount = _getAmountEx(_marketPrice, _amount, false);
        userTotalSwap[_msgSender()][upper(_ticker)][false] = userTotalSwap[
            _msgSender()
        ][upper(_ticker)][false].add(_amount);
        totalSwap[upper(_ticker)][false] = totalSwap[upper(_ticker)][false].add(
            _amount
        );
        uint fee = getAmount.multiplyDecimal(ex_fee);
        base_fee[upper(_ticker)] = base_fee[upper(_ticker)].add(fee);
        require(base_liquidity[upper(_ticker)] >= getAmount, "No liquidity!");

        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].sub(
            getAmount
        );

        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].add(
            _amount
        );
        _tr(getAmount.sub(fee), _msgSender(), base_address[upper(_ticker)]);
        emit Swaped(
            _msgSender(),
            _amount,
            getAmount.sub(fee),
            false,
            block.timestamp,
            fee,
            _ticker
        );
    }

    function getNativeCurrencyWitthToken(
        uint256 _amount,
        string memory _ticker
    ) external {
        Ora _ora = Ora(address(this));

        require(isListed[upper(_ticker)], "Invalid Pair");
        require(_amount > 0, "Zero value provided!");
        _tFrom(token_address[upper(_ticker)], _amount, address(this));
        uint256 _marketPrice = _ora.price(_ticker);
        uint256 getAmount = _getAmountEx(_marketPrice, _amount, false);
        userTotalSwap[_msgSender()][upper(_ticker)][false] = userTotalSwap[
            _msgSender()
        ][upper(_ticker)][false].add(_amount);
        totalSwap[upper(_ticker)][false] = totalSwap[upper(_ticker)][false].add(
            _amount
        );
        uint fee = getAmount.multiplyDecimal(ex_fee);
        base_fee[upper(_ticker)] = base_fee[upper(_ticker)].add(fee);
        require(base_liquidity[upper(_ticker)] >= getAmount, "No liquidity!");

        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].sub(
            getAmount
        );

        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].add(
            _amount
        );

        (bool sent, bytes memory data) = _msgSender().call{
            value: getAmount.sub(fee)
        }("");
        require(sent, "Failed to send Ether");
        emit Swaped(
            _msgSender(),
            _amount,
            getAmount.sub(fee),
            false,
            block.timestamp,
            fee,
            _ticker
        );
    }

    function getTokenExWithNativeToken(string memory _ticker) external payable {
        require(isListed[upper(_ticker)], "Invalid Pair");
        uint256 _amount = msg.value;
        require(_amount > 0, "Zero value provided!");
        Ora _ora = Ora(address(this));
        uint256 _marketPrice = _ora.price(_ticker);
        uint256 getAmount = _getAmountEx(_marketPrice, _amount, true);
        userTotalSwap[_msgSender()][upper(_ticker)][true] = userTotalSwap[
            _msgSender()
        ][upper(_ticker)][true].add(_amount);
        totalSwap[upper(_ticker)][true] = totalSwap[upper(_ticker)][true].add(
            _amount
        );

        uint fee = getAmount.multiplyDecimal(ex_fee);
        token_fee[upper(_ticker)] = token_fee[upper(_ticker)].add(fee);
        require(token_liquidity[upper(_ticker)] >= getAmount, "No liquidity!");
        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].sub(
            getAmount
        );

        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].add(
            _amount
        );

        _tr(getAmount.sub(fee), _msgSender(), token_address[upper(_ticker)]);
        emit Swaped(
            _msgSender(),
            _amount,
            getAmount.sub(fee),
            true,
            block.timestamp,
            fee,
            _ticker
        );
    }

    function getTokenEx(uint256 _amount, string memory _ticker) external {
        require(_amount > 0, "Zero value provided!");
        require(isListed[upper(_ticker)], "Invalid Pair");
        _tFrom(base_address[upper(_ticker)], _amount, address(this));
        Ora _ora = Ora(address(this));
        uint256 _marketPrice = _ora.price(_ticker);
        uint256 getAmount = _getAmountEx(_marketPrice, _amount, true);
        userTotalSwap[_msgSender()][upper(_ticker)][true] = userTotalSwap[
            _msgSender()
        ][upper(_ticker)][true].add(_amount);
        totalSwap[upper(_ticker)][true] = totalSwap[upper(_ticker)][true].add(
            _amount
        );

        uint fee = getAmount.multiplyDecimal(ex_fee);
        token_fee[upper(_ticker)] = token_fee[upper(_ticker)].add(fee);
        require(token_liquidity[upper(_ticker)] >= getAmount, "No liquidity!");
        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].sub(
            getAmount
        );

        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].add(
            _amount
        );

        _tr(getAmount.sub(fee), _msgSender(), token_address[upper(_ticker)]);
        emit Swaped(
            _msgSender(),
            _amount,
            getAmount.sub(fee),
            true,
            block.timestamp,
            fee,
            _ticker
        );
    }

    function listAssetEx(
        string memory _ticker,
        address _token_address,
        address _base_address
    ) external onlyOwner {
        token_address[upper(_ticker)] = _token_address;
        base_address[upper(_ticker)] = _base_address;
        isListed[upper(_ticker)] = true;
        emit NewAsset(
            _ticker,
            _token_address,
            _base_address,
            _msgSender(),
            block.timestamp
        );
    }

    function listAssetExForNativeCurrency(
        string memory _ticker,
        address _token_address
    ) external onlyOwner {
        token_address[upper(_ticker)] = _token_address;
        base_address[upper(_ticker)] = address(0);
        isListed[upper(_ticker)] = true;
        emit NewAsset(
            _ticker,
            _token_address,
            address(0),
            _msgSender(),
            block.timestamp
        );
    }

    function addLiquidityForNativeCurrency(
        uint256 _tokenInamount,
        string memory _ticker
    ) external payable {
        require(isListed[upper(_ticker)], "Invalid Pair");
        uint256 _baseInamount = msg.value;
        require(_baseInamount > 0, "Zero value provided!");
        require(_tokenInamount > 0, "Zero value provided!");
        Ora _ora = Ora(address(this));
        uint256 _marketPrice = _ora.price(_ticker);
        require(
            _baseInamount.divideDecimal(_marketPrice) >= _tokenInamount,
            "Invalid liquidity"
        );
        _tFrom(token_address[upper(_ticker)], _tokenInamount, address(this));
        userBaseliquidity[upper(_ticker)][_msgSender()] = userBaseliquidity[
            upper(_ticker)
        ][_msgSender()].add(_baseInamount);
        userTokenliquidity[upper(_ticker)][_msgSender()] = userTokenliquidity[
            upper(_ticker)
        ][_msgSender()].add(_tokenInamount);
        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].add(
            _tokenInamount
        );
        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].add(
            _baseInamount
        );
        emit liquidityAdded(
            _msgSender(),
            _baseInamount,
            _tokenInamount,
            _ticker,
            block.timestamp
        );
    }

    function addLiquidity(
        uint256 _baseInamount,
        uint256 _tokenInamount,
        string memory _ticker
    ) external {
        require(isListed[upper(_ticker)], "Invalid Pair");
        require(_baseInamount > 0, "Zero value provided!");
        require(_tokenInamount > 0, "Zero value provided!");
        Ora _ora = Ora(address(this));
        uint256 _marketPrice = _ora.price(_ticker);
        require(
            _baseInamount.divideDecimal(_marketPrice) >= _tokenInamount,
            "Invalid liquidity"
        );
        _tFrom(token_address[upper(_ticker)], _tokenInamount, address(this));
        _tFrom(base_address[upper(_ticker)], _baseInamount, address(this));
        userBaseliquidity[upper(_ticker)][_msgSender()] = userBaseliquidity[
            upper(_ticker)
        ][_msgSender()].add(_baseInamount);
        userTokenliquidity[upper(_ticker)][_msgSender()] = userTokenliquidity[
            upper(_ticker)
        ][_msgSender()].add(_tokenInamount);
        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].add(
            _tokenInamount
        );
        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].add(
            _baseInamount
        );
        emit liquidityAdded(
            _msgSender(),
            _baseInamount,
            _tokenInamount,
            _ticker,
            block.timestamp
        );
    }

    function getLP(uint256 _lP, uint256 _lPR) internal pure returns (uint) {
        uint256 lP = _lP;
        uint256 lPR = _lPR;
        uint256 lpercent = lPR.divideDecimal(lP);
        return lpercent.multiplyDecimal(lP);
    }

    function removeLiquidity(string memory _ticker) external {
        require(isListed[upper(_ticker)], "Invalid Pair");
        require(
            userBaseliquidity[upper(_ticker)][_msgSender()] > 0,
            "Add liquidity to continue!"
        );
        require(
            userTokenliquidity[upper(_ticker)][_msgSender()] > 0,
            "Add liquidity to continue!"
        );
        uint256 baseLP = getLP(
            base_liquidity[upper(_ticker)],
            userBaseliquidity[upper(_ticker)][_msgSender()]
        );
        uint256 tokenLP = getLP(
            token_liquidity[upper(_ticker)],
            userTokenliquidity[upper(_ticker)][_msgSender()]
        );
        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].sub(
            baseLP
        );
        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].sub(
            tokenLP
        );
        userTokenliquidity[upper(_ticker)][_msgSender()] = 0;
        userBaseliquidity[upper(_ticker)][_msgSender()] = 0;
        _tr(tokenLP, _msgSender(), token_address[upper(_ticker)]);
        _tr(baseLP, _msgSender(), base_address[upper(_ticker)]);
        emit liquidityRemoved(
            _msgSender(),
            baseLP,
            tokenLP,
            _ticker,
            block.timestamp
        );
    }

    function removeLiquidityForNativeCurrency(string memory _ticker) external {
        require(isListed[upper(_ticker)], "Invalid Pair");
        require(
            userBaseliquidity[upper(_ticker)][_msgSender()] > 0,
            "Add liquidity to continue!"
        );
        require(
            userTokenliquidity[upper(_ticker)][_msgSender()] > 0,
            "Add liquidity to continue!"
        );
        uint256 baseLP = getLP(
            base_liquidity[upper(_ticker)],
            userBaseliquidity[upper(_ticker)][_msgSender()]
        );
        uint256 tokenLP = getLP(
            token_liquidity[upper(_ticker)],
            userTokenliquidity[upper(_ticker)][_msgSender()]
        );
        base_liquidity[upper(_ticker)] = base_liquidity[upper(_ticker)].sub(
            baseLP
        );
        token_liquidity[upper(_ticker)] = token_liquidity[upper(_ticker)].sub(
            tokenLP
        );
        userTokenliquidity[upper(_ticker)][_msgSender()] = 0;
        userBaseliquidity[upper(_ticker)][_msgSender()] = 0;
        _tr(tokenLP, _msgSender(), token_address[upper(_ticker)]);
        (bool sent, bytes memory data) = _msgSender().call{value: baseLP}("");
        require(sent, "Failed to send Ether");
        emit liquidityRemoved(
            _msgSender(),
            baseLP,
            tokenLP,
            _ticker,
            block.timestamp
        );
    }

    function getUserTotalSwap(
        address _user,
        string memory _ticker
    )
        external
        view
        returns (
            uint256 _base,
            uint256 _token,
            uint256 _baseLp,
            uint256 _tokenLp,
            uint256 _userBaseLp,
            uint256 _userTokenLp
        )
    {
        return (
            userTotalSwap[_user][upper(_ticker)][true],
            userTotalSwap[_user][upper(_ticker)][false],
            base_liquidity[upper(_ticker)],
            token_liquidity[upper(_ticker)],
            userBaseliquidity[upper(_ticker)][_msgSender()],
            userTokenliquidity[upper(_ticker)][_msgSender()]
        );
    }

    function getSystemTotalSwap(
        string memory _ticker
    )
        external
        view
        returns (
            uint256 _base,
            uint256 _token,
            uint256 _base_fee,
            uint256 _token_fee,
            uint256 _currentFee
        )
    {
        return (
            totalSwap[upper(_ticker)][true],
            totalSwap[upper(_ticker)][false],
            base_fee[upper(_ticker)],
            token_fee[upper(_ticker)],
            ex_fee
        );
    }

    function delistAsset(string memory _ticker) external onlyOwner {
        isListed[upper(_ticker)] = false;
    }

    function setFee(uint256 _fee) external onlyOwner {
        ex_fee = _fee;
    }

    receive() external payable {}

    fallback() external payable {}
}
