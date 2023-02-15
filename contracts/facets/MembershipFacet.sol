// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
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

contract MembershipFacet{
AppStorage internal s;
using SafeMath for uint256;
using SafeDecimalMath for uint;
enum MembershipPlan{ MONTHLY, SEMIANNUALLY, ANNUALLY }
event Subscribed(address user, uint amount, uint expiryDate, uint plan, uint time);
event PlansEdited(uint _monthly, uint _semiAnnually, uint _Annually, uint time, address intiator);

modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }  

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
function configurePlan(uint _monthlyPrice, uint _semiAnnuallyPlan,uint _annuallyPlan ) external onlyOwner{
    s.plan[uint(MembershipPlan.MONTHLY)] = _monthlyPrice;
    s.plan[uint(MembershipPlan.SEMIANNUALLY)] = _semiAnnuallyPlan;
    s.plan[uint(MembershipPlan.ANNUALLY)] = _annuallyPlan;
   emit PlansEdited(_monthlyPrice, _semiAnnuallyPlan, _annuallyPlan, block.timestamp, _msgSender());
}

function getConfiguration() external view returns(uint _monthly, uint _semiAnnually, uint _annually){
return(s.plan[uint(MembershipPlan.MONTHLY)], s.plan[uint(MembershipPlan.SEMIANNUALLY)], s.plan[uint(MembershipPlan.ANNUALLY)]);
}
function montlyPlan() external {
   address user = _msgSender();
   require(block.timestamp >= s.expiryDate[user], "Wait until your current plan elapses.");
   uint amount =  s.plan[uint(MembershipPlan.MONTHLY)];
   require(amount > 0, "Invalid plan");
   uint expiryDate = block.timestamp.add(30 days);
   require(subscribe(amount, user, expiryDate, uint(MembershipPlan.SEMIANNUALLY)), "Unable to subscribe");
}


function semiAnnuallyPlan() external {
    address user = _msgSender();
    require(block.timestamp >= s.expiryDate[user], "Wait until your current plan elapses.");
    uint amount =  s.plan[uint(MembershipPlan.SEMIANNUALLY)];
    require(amount > 0, "Invalid plan");
    uint expiryDate = block.timestamp.add(180 days);
    require(subscribe(amount, user, expiryDate, uint(MembershipPlan.SEMIANNUALLY)), "Unable to subscribe");
}

function annually() external {
    address user = _msgSender();
    require(block.timestamp >= s.expiryDate[user], "Wait until your current plan elapses.");
    uint amount =  s.plan[uint(MembershipPlan.ANNUALLY)];
    require(amount > 0, "Invalid plan");
    uint expiryDate = block.timestamp.add(365 days);
    require(subscribe(amount, user, expiryDate, uint(MembershipPlan.ANNUALLY)), "Unable to subscribe");
}


function subscribe(uint _amount, address _user, uint _expiryDate, uint plan) internal returns (bool){
    IERC20 iERC20 = IERC20(s.egcAddr);
    require(iERC20.allowance(_user, address(this)) >= _amount, "Insufficient EGC allowance for subscription!");
    require(iERC20.transferFrom(_user, address(this), _amount), "Fail to transfer");
    s.expiryDate[_user] = _expiryDate;
    emit Subscribed(_user,_amount, _expiryDate,  plan, block.timestamp);
    return true;
}


}