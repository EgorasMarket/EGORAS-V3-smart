// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../interfaces/IERC20.sol";
import "../extensions/IERC20Metadata.sol";
import "../utils/Context.sol";
import "../extensions/Ownable.sol";
import "../libraries/SafeMath.sol";

contract MartGPTToken is Context, Ownable {
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    address private _convertAddress;
    address private _martGPTMarketAddress;
    uint256 private _totalCap;
    uint private _nextDisburseDate;
    uint private _dailyMining;

    constructor(
        string memory name_,
        string memory symbol_,
        address convertAddress_,
        address martGPTMarketAddress_,
        uint256 totalCap_,
        uint256 dailyMining_
    ) {
        _name = name_;
        _symbol = symbol_;
        _convertAddress = convertAddress_;
        _totalCap = totalCap_;
        _martGPTMarketAddress = martGPTMarketAddress_;
        _dailyMining = dailyMining_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) external virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        address spender = _msgSender();
        _burn(account, amount);
        _spendAllowance(account, spender, amount);
        return true;
    }

    function dailyBlockMining() external returns (bool) {
        require(_msgSender() == _martGPTMarketAddress, "Access denied!");
        require(block.timestamp >= _nextDisburseDate, "Wait till next day!");
        _nextDisburseDate = block.timestamp.add(1 days);
        _checkCap(_dailyMining);
        _mint(_martGPTMarketAddress, _dailyMining);
        return true;
    }

    function convertTokenToMartGPTToken(
        address account,
        uint256 amount
    ) external returns (bool) {
        IERC20 __ierc20 = IERC20(_convertAddress);
        _checkCap(amount);
        _mint(account, amount);
        require(
            __ierc20.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient allowance!"
        );
        __ierc20.burnFrom(_msgSender(), amount);
        //__ierc20.transferFrom(_msgSender(), address(this), amount);

        return true;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender).add(addedValue));
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance.sub(subtractedValue));
        }

        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _update(from, to, amount);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0)) {
            _totalSupply = _totalSupply.add(amount);
        } else {
            uint256 fromBalance = _balances[from];
            require(
                fromBalance >= amount,
                "ERC20: transfer amount exceeds balance"
            );
            unchecked {
                _balances[from] = fromBalance.sub(amount);
            }
        }

        if (to == address(0)) {
            unchecked {
                _totalSupply = _totalSupply.sub(amount);
            }
        } else {
            unchecked {
                _balances[to] = _balances[to].add(amount);
            }
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _update(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _update(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _checkCap(uint256 amount) internal virtual {
        require(_totalCap >= _totalSupply.add(amount), "Total Cap exceeded");
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance.sub(amount));
            }
        }
    }
}
