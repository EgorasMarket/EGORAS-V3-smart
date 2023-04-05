// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/Pancakes.sol";
import "../libraries/Utils.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20PAN {
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

    function swapExactBNBForEUSD(
        uint amountOutMin,
        address tokenOut,
        address[] calldata routerPath
    ) external payable {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = routerPath[1];
        IERC20PAN(pancakeRouter.WETH()).approve(
            address(pancakeRouter),
            msg.value
        );
        pancakeRouter.swapExactETHForTokens{value: msg.value}(
            amountOutMin,
            path,
            address(this),
            block.timestamp.add(6 minutes)
        );

        uint256[] memory amounts = pancakeRouter.getAmountsOut(msg.value, path);
        IERC20PAN ierc20 = IERC20PAN(tokenOut);
        require(ierc20.mint(_msgSender(), amounts[1]), "Sending faild");
        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            pancakeRouter.WETH(),
            tokenOut,
            msg.value,
            amounts[1]
        );
    }

    function swapExactTokensForEUSD(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath
    ) external {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        IERC20PAN(path[0]).transferFrom(_msgSender(), address(this), amountIn);
        IERC20PAN(path[0]).approve(address(pancakeRouter), amountIn);
        address[] memory innerPath = new address[](2);
        innerPath[0] = path[0];
        innerPath[1] = routerPath[1];
        pancakeRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            innerPath,
            address(this),
            block.timestamp.add(6 minutes)
        );
        uint256[] memory amounts = pancakeRouter.getAmountsOut(amountIn, path);
        IERC20PAN ierc20 = IERC20PAN(path[0]);
        require(ierc20.mint(_msgSender(), amounts[1]), "Sending faild");
        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            amountIn,
            amounts[1]
        );
    }

    function swapExactEUSDForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath
    ) external {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        IERC20PAN(path[0]).burnFrom(_msgSender(), amountIn);
        IERC20PAN(routerPath[1]).approve(address(pancakeRouter), amountIn);
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

    function swapExactEUSDforBNB(
        address token,
        uint amountIn,
        uint amountOutMin,
        address[] calldata routerPath
    ) external {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        IERC20PAN(token).burnFrom(_msgSender(), amountIn);
        address[] memory path = new address[](2);
        path[0] = routerPath[1];
        path[1] = pancakeRouter.WETH();
        IERC20PAN(path[0]).approve(address(pancakeRouter), amountIn);
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

    function swapBNBForExactEUSD(
        uint amountOut,
        address tokenOut,
        address[] calldata routerPath
    ) external payable {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = routerPath[1];
        IERC20PAN(path[0]).approve(address(pancakeRouter), msg.value);
        pancakeRouter.swapETHForExactTokens{value: msg.value}(
            amountOut,
            path,
            address(this),
            block.timestamp.add(6 minutes)
        );
        IERC20PAN ierc20 = IERC20PAN(tokenOut);
        require(ierc20.mint(_msgSender(), amountOut), "Sending faild");
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

    function swapEUSDforExactToken(
        uint amountInMax,
        uint amountOut,
        address[] calldata path,
        address[] calldata routerPath
    ) external {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        IERC20PAN(path[0]).burnFrom(_msgSender(), amountInMax);
        IERC20PAN(routerPath[1]).approve(address(pancakeRouter), amountInMax);
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

    function swapTokensforExactEUSD(
        uint amountInMax,
        uint amountOut,
        address[] calldata path,
        address[] calldata routerPath
    ) external {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        IERC20PAN(path[0]).transferFrom(
            _msgSender(),
            address(this),
            amountInMax
        );
        IERC20PAN(path[0]).approve(address(pancakeRouter), amountInMax);
        pancakeRouter.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            address(this),
            block.timestamp.add(6 minutes)
        );
        IERC20PAN ierc20 = IERC20PAN(path[0]);
        require(ierc20.mint(_msgSender(), amountOut), "Sending faild");
        emit SwapTransfer(
            address(pancakeRouter),
            _msgSender(),
            path[0],
            path[1],
            amountInMax,
            amountOut
        );
    }

    function swapEUSDForExactBNB(
        address token,
        uint amountInMax,
        uint amountOut,
        address[] calldata routerPath
    ) external {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        IERC20PAN(token).burnFrom(_msgSender(), amountInMax);
        address[] memory path = new address[](2);
        path[0] = routerPath[1];
        path[1] = pancakeRouter.WETH();
        IERC20PAN(path[0]).approve(address(pancakeRouter), amountInMax);
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

    function getWethAddress(
        address[] calldata routerPath
    ) external view returns (address pancakeRouter_weth) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        return pancakeRouter.WETH();
    }

    function getAmountsOut(
        uint amountIn,
        address[] calldata path,
        address[] calldata routerPath
    ) external view returns (uint[] memory amounts) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
        return pancakeRouter.getAmountsOut(amountIn, path);
    }

    function getAmountsIn(
        uint amountOut,
        address[] calldata path,
        address[] calldata routerPath
    ) external view returns (uint[] memory amounts) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);

        return pancakeRouter.getAmountsIn(amountOut, path);
    }
}

// function addLiquidity(
//     address tokenA,
//     address tokenB,
//     uint amountADesired,
//     uint amountBDesired,
//     address[] calldata routerPath
// ) external returns (uint amountA, uint amountB, uint liquidity) {
//     IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerPath[0]);
//     IERC20PAN(tokenA).transferFrom(_msgSender(), address(this), amountADesired);
//     IERC20PAN(tokenB).transferFrom(_msgSender(), address(this), amountBDesired);

//     IERC20PAN(tokenA).approve(address(pancakeRouter), amountADesired);
//     IERC20PAN(tokenB).approve(address(pancakeRouter), amountBDesired);

//     (uint amountA, uint amountB, uint liquidity) = pancakeRouter.addLiquidity(
//         tokenA,
//         tokenB,
//         amountADesired,
//         amountBDesired,
//         0,
//         0,
//         _msgSender(),
//         block.timestamp.add(6 minutes)
//     );
// }

// function addLiquidityETH(
//     address token,
//     uint amountTokenDesired,
//     uint amountTokenMin,
//     uint amountETHMin,
//     address to,
//     uint deadline
// ) external payable returns (uint amountToken, uint amountETH, uint liquidity) {}

// 0.5% minus 0.02n,
// token other than eusd should trasact direct and minus 0.5
// either you bring eusd or collect eusd
