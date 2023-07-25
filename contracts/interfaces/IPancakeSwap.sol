// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IPancakeSwap {
    function swapExactEUSDforBNB(
        address token,
        uint amountIn,
        uint amountOutMin,
        address[] calldata routerPath
    ) external;

    function swapExactBNBForEUSD(
        uint amountOutMin,
        address tokenOut,
        address[] calldata routerPath
    ) external payable;

    function swapExactEUSDForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath
    ) external;

    function swapExactTokensForEUSD(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path,
        address[] calldata routerPath
    ) external view returns (uint[] memory amounts);
}
