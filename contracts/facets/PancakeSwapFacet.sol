// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/Pancakes.sol";
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
}

contract PancakeSwapFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    IPancakeRouter02 public pancakeRouter;
    event SwapTransfer(
        address from,
        address to,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

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

    function setRouterAddress(
        address _pancakeRouterAddress
    ) external onlyOwner {
        pancakeRouter = IPancakeRouter02(_pancakeRouterAddress);
    }

    function swapExactBNBForTokens(
        uint amountOutMin,
        address tokenOut
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenOut;
        IERC20(pancakeRouter.WETH()).approve(address(pancakeRouter), msg.value);
        pancakeRouter.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            _msgSender(),
            block.timestamp.add(6 minutes)
        );

        uint256[] memory amounts = pancakeRouter.getAmountsOut(msg.value, path);
        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            pancakeRouter.WETH(),
            tokenOut,
            msg.value,
            amounts[1]
        );
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path
    ) external {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20(path[0]).approve(address(pancakeRouter), amountIn);
        pancakeRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            _msgSender(),
            block.timestamp.add(6 minutes)
        );
        uint256[] memory amounts = pancakeRouter.getAmountsOut(amountIn, path);

        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            amountIn,
            amounts[1]
        );
    }

    function swapExactTokensforBNB(
        address token,
        uint amountIn,
        uint amountOutMin
    ) external {
        IERC20(token).transferFrom(_msgSender(), address(this), amountIn);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = pancakeRouter.WETH();
        IERC20(path[0]).approve(address(pancakeRouter), amountIn);
        pancakeRouter.swapExactTokensForETH(
            amountIn,
            amountOutMin,
            path,
            _msgSender(),
            block.timestamp.add(6 minutes)
        );

        uint256[] memory amounts = pancakeRouter.getAmountsOut(amountIn, path);

        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            amountIn,
            amounts[1]
        );
    }

    function swapBNBForExactTokens(
        uint amountOut,
        address tokenOut
    ) external payable {
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = tokenOut;
        IERC20(path[0]).approve(address(pancakeRouter), msg.value);
        pancakeRouter.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            _msgSender(),
            block.timestamp.add(6 minutes)
        );
        // uint256[] memory amounts = pancakeRouter.getAmountsIn(amountOut, path); front end call
        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            msg.value,
            amountOut
        );
    }

    function swapTokensForExactToken(
        uint amountInMax,
        uint amountOut,
        address[] calldata path
    ) external {
        IERC20(path[0]).transferFrom(_msgSender(), address(this), amountInMax);
        IERC20(path[0]).approve(address(pancakeRouter), amountInMax);
        pancakeRouter.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            _msgSender(),
            block.timestamp.add(6 minutes)
        );

        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            amountInMax,
            amountOut
        );
    }

    function swapTokensForExactBNB(
        address token,
        uint amountInMax,
        uint amountOut
    ) external {
        IERC20(token).transferFrom(_msgSender(), address(this), amountInMax);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = pancakeRouter.WETH();
        IERC20(path[0]).approve(address(pancakeRouter), amountInMax);
        pancakeRouter.swapTokensForExactETH(
            amountOut,
            amountInMax,
            path,
            _msgSender(),
            block.timestamp.add(6 minutes)
        );

        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            amountInMax,
            amountOut
        );
    }

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts) {
        return pancakeRouter.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts) {
        return pancakeRouter.getAmountsIn(amountOut, path);
    }
}
