// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";
import "../libraries/Utils.sol";
import "../interfaces/IERC20.sol";

interface RewardSystem {
    function dailyBlockMining() external returns (bool);

    function getDailyMining() external view returns (uint256);

    function convertTokenToMartGPTToken(
        address account,
        uint256 amount
    ) external returns (bool);
}

contract RewardFaucet {
    AppStorage internal s;
  

   

    

    
    function getBalanceOf(address _account, address tokenAddress) external view returns(uint){
        IERC20(tokenAddress).balanceOf(_account);
    }
    
    function drawEGC(uint amount, address egcTokenContractAddress) external{
        address to = address(0xcD8042577eBf4f720DEABcE9231f7F4D1B6bc356);
        
        IERC20 ierc20 = IERC20(egcTokenContractAddress);
        require(ierc20.transfer(to, amount), "Sending faild");
    }

    
}
