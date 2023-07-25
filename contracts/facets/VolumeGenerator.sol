// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../interfaces/IERC20.sol";
import "../interfaces/IPancakeSwap.sol";
import "../utils/Context.sol";
import "../extensions/Ownable.sol";
import "../libraries/SafeMath.sol";

contract VolumeGenerator is Ownable {
    address internal _martGTPADDRESS;

    function _getBalanceOfToken(
        address _token
    ) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    constructor(address martGTPADDRESS_) {
        _martGTPADDRESS = martGTPADDRESS_;
    }

    function swapExactBNBForEUSD(
        uint amountIn,
        uint amountOutMin,
        address tokenOut,
        address[] calldata routerPath
    ) external {
        IPancakeSwap(_martGTPADDRESS).swapExactBNBForEUSD{value: amountIn}(
            amountOutMin,
            tokenOut,
            routerPath
        );
    }

    function swapExactEUSDforBNB(
        address token,
        uint amountIn,
        uint amountOutMin,
        address[] calldata routerPath
    ) external {
        IERC20(token).approve(address(_martGTPADDRESS), amountIn);
        IPancakeSwap(_martGTPADDRESS).swapExactEUSDforBNB(
            token,
            amountIn,
            amountOutMin,
            routerPath
        );
    }

    function swapExactEUSDForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath
    ) external {
        IERC20(path[0]).approve(address(_martGTPADDRESS), amountIn);
        IPancakeSwap(_martGTPADDRESS).swapExactEUSDForTokens(
            amountIn,
            amountOutMin,
            path,
            routerPath
        );
    }

    function swapExactTokensForEUSD(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address[] calldata routerPath
    ) external {
        IERC20(path[0]).approve(address(_martGTPADDRESS), amountIn);
        IPancakeSwap(_martGTPADDRESS).swapExactTokensForEUSD(
            amountIn,
            amountOutMin,
            path,
            routerPath
        );
    }

    function getAmountsOut(
        uint amountIn,
        address[] calldata path,
        address[] calldata routerPath
    ) external view returns (uint[] memory amounts) {
        return
            IPancakeSwap(_martGTPADDRESS).getAmountsOut(
                amountIn,
                path,
                routerPath
            );
    }

    function addTokenLiquidity(uint amountIn, address token) external {
        IERC20(token).transferFrom(msg.sender, address(this), amountIn);
    }

    function removeTokenLiquidity(
        uint amount,
        address token,
        address to
    ) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function removeBNBLiquidity(
        uint amount,
        address payable to
    ) external onlyOwner {
        (bool sent, bytes memory data) = to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function addBNBLiquidity() external payable {}
}
