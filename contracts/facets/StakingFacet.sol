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
    event Royalty(address user, uint amount, uint time);
    modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }  

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function monthly(uint amount) external{
     require(s.member[_msgSender()], "You're not a member, please subscribe to any membership plan and try again");
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
     require(s.member[_msgSender()], "You're not a member, please subscribe to any membership plan and try again");
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

 
   
   function takeRoyalty() external{
    require(block.timestamp >= s.nextRoyaltyTakePeriod[_msgSender()], "Not yet due!");
    uint getNumDays = DateTime.getDiff(s.nextRoyaltyTakePeriod[_msgSender()], block.timestamp);
    uint rolyalty =  uint(uint(s.dailyRoyalty[_msgSender()]).divideDecimal(uint(DateTime.DIVISOR_A)).multiplyDecimal(uint(getNumDays)));
    IERC20 eusd = IERC20(s.eusdAddr);
    require(eusd.mint(_msgSender(), rolyalty), "Fail to transfer fund");
    s.totalRoyaltyTaken[_msgSender()] = s.totalRoyaltyTaken[_msgSender()].add(rolyalty);
    s.nextRoyaltyTakePeriod[_msgSender()] = block.timestamp.add(1 days);
    emit Royalty(_msgSender(), rolyalty, block.timestamp);
   }


   function royaltyStats(address user) external view returns(uint _dailyRoyalty, uint _totalStake, uint _nextRoyaltyTakePeriod, uint _lockPeriod, uint _totalRoyaltyTaken){
    return (s.dailyRoyalty[user], s.userTotalStake[user], s.nextRoyaltyTakePeriod[user], s.lockPeriod[user], s.totalRoyaltyTaken[user]);
   }


}
