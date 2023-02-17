// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/DateTime.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20 {
    function totalSupply() external view  returns (uint256);
    function balanceOf(address account) external view  returns (uint256);
    function transfer(address recipient, uint256 amount) external  returns (bool);
    function allowance(address owner, address spender) external  view returns (uint256);
    function approve(address spender, uint256 amount) external  returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external  returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external;
}

contract StakingFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint;
    enum Stakinglan{ MONTHLY, ANNUALLY } 
    event Stake(address user, uint amount, uint plan, uint dailyRoyalty, uint totalRoyalty, uint time);
    modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }  

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function monthly(uint amount) external{
     require(amount > 0, "invalid amount");
     uint inusd = s.ticker[s.egcusd].multiplyDecimal(amount);
     require(inusd >= s.stakingPlan[uint(Stakinglan.MONTHLY)] , "Please increase your staking amount." );
     IERC20 iERC20 = IERC20(s.egcAddr);
     require(iERC20.allowance(_msgSender(), address(this)) >= amount, "Insufficient EGC allowance for staking!");
     require(iERC20.transferFrom(_msgSender(), address(this), amount), "Error!");
     uint userCurrentTotal = s.userTotalStakeUsd[_msgSender()].add(inusd);
     s.userTotalStake[_msgSender()] = s.userTotalStake[_msgSender()].add(amount);
     s.userTotalStakeUsd[_msgSender()] = userCurrentTotal;
     uint yearlyRoyalty = userCurrentTotal.multiplyDecimal(DateTime.YEARLY_INTEREST_RATE);
     uint dailyInterest = yearlyRoyalty.divideDecimal(DateTime.DAYS_IN_A_YEAR);
     uint lockPeriod = block.timestamp.add(30 days);
     uint nextRoyaltyTakePeriod = block.timestamp.add(1 days);
     s.dailyRoyalty[_msgSender()] = dailyInterest;
     s.lockPeriod[_msgSender()] = lockPeriod;
     s.nextRoyaltyTakePeriod[_msgSender()] = nextRoyaltyTakePeriod;
     emit Stake(_msgSender(), amount, uint(Stakinglan.MONTHLY), dailyInterest, yearlyRoyalty, block.timestamp);
    }


     function annually(uint amount) external{
     require(amount > 0, "invalid amount");
     uint inusd = s.ticker[s.egcusd].multiplyDecimal(amount);
     require(inusd >= s.stakingPlan[uint(Stakinglan.ANNUALLY)] , "Please increase your staking amount." );
     IERC20 iERC20 = IERC20(s.egcAddr);
     require(iERC20.allowance(_msgSender(), address(this)) >= amount, "Insufficient EGC allowance for staking!");
     require(iERC20.transferFrom(_msgSender(), address(this), amount), "Error!");
     uint userCurrentTotal = s.userTotalStakeUsd[_msgSender()].add(inusd);
     s.userTotalStake[_msgSender()] = s.userTotalStake[_msgSender()].add(amount);
     s.userTotalStakeUsd[_msgSender()] = userCurrentTotal;
     uint yearlyRoyalty = userCurrentTotal.multiplyDecimal(DateTime.YEARLY_INTEREST_RATE);
     uint dailyInterest = yearlyRoyalty.divideDecimal(DateTime.DAYS_IN_A_YEAR);
     uint lockPeriod = block.timestamp.add(365 days);
     uint nextRoyaltyTakePeriod = block.timestamp.add(1 days);
     s.dailyRoyalty[_msgSender()] = dailyInterest;
     s.lockPeriod[_msgSender()] = lockPeriod;
     s.nextRoyaltyTakePeriod[_msgSender()] = nextRoyaltyTakePeriod;
     emit Stake(_msgSender(), amount, uint(Stakinglan.ANNUALLY), dailyInterest, yearlyRoyalty, block.timestamp);
    }


    

}
