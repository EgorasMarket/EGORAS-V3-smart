// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
interface IEgorasLoanV2Facet {

 function internalLending(
        address _branch,
        address _user,
        uint _amount,
        uint loanID
    ) external;
function internalTopup(uint _loanID, uint _amount, address _user) external;
}
contract EgorasLoanV2ReferralFacet{
using SafeMath for uint256;
mapping(address => uint) refferalReward;
mapping(address => uint) refferalRewardUsedForLending;
mapping(address => uint) userWelcomeBonusUsedForLending;
mapping(address => uint) userWelcomeBonus;
mapping(address => address[]) myReferrals;
 uint private referralBonus;
 uint private welcomeBonus;
mapping(address => bool) hasDoneKYC;
  mapping (address=>bool) private rpythia;
  event RPythiaAdded(address _pythia, address _addBy, uint _time);
   event RPythiaSuspended(address _pythia, address _addBy, uint _time);
event KYC(uint _time, address user, address _upline);
modifier onlyRPythia{
        require(rpythia[msg.sender], "Access denied. Only Pythia is allowed!");
        _;
    }
 modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }  

 function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

  function setRPythia(address _pythia) external onlyOwner{
    rpythia[_pythia] = true;
    emit RPythiaAdded(_pythia, msg.sender, block.timestamp);
  }

  function suspendRPythia(address _pythia) external onlyOwner{
    rpythia[_pythia] = false;
    emit RPythiaSuspended(_pythia, msg.sender, block.timestamp);
  }
 // Start of referral system
 function kycUsers(address[] calldata _users, address[] calldata _upline) external onlyRPythia{
    require(_users.length == _upline.length, "Users and Upline must be of equal length");
    for (uint256 i; i < _users.length; i++) {
        if(!hasDoneKYC[_users[i]]){
        myReferrals[_upline[i]].push(_users[i]);
        userWelcomeBonus[_users[i]] = userWelcomeBonus[_users[i]].add(welcomeBonus); 
        refferalReward[_upline[i]] = refferalReward[_upline[i]].add(referralBonus);   
        emit KYC(block.timestamp,_users[i],_upline[i]);
        }
   
        }
  }

 function lend(uint amount, address branch, uint loanID, bool isWelcomebonus) external{
    IEgorasLoanV2Facet e = IEgorasLoanV2Facet(address(this));
    isWelcomebonus ? require(userWelcomeBonus[msg.sender] >= amount, "No fund") :  require(refferalReward[msg.sender] >= amount, "No fund");
   
    isWelcomebonus ? userWelcomeBonus[msg.sender] = userWelcomeBonus[msg.sender].sub(amount) : refferalReward[msg.sender] = refferalReward[msg.sender].sub(amount);
    isWelcomebonus ? userWelcomeBonusUsedForLending[msg.sender] = userWelcomeBonusUsedForLending[msg.sender].add(amount) : refferalRewardUsedForLending[msg.sender] = refferalRewardUsedForLending[msg.sender].add(amount);
 e.internalLending(branch, msg.sender, amount, loanID);
  }

   function topup(uint amount,uint loanID, bool isWelcomebonus) external{
    IEgorasLoanV2Facet e = IEgorasLoanV2Facet(address(this));
    isWelcomebonus ? require(userWelcomeBonus[msg.sender] >= amount, "No fund") :  require(refferalReward[msg.sender] >= amount, "No fund");
    
    isWelcomebonus ? userWelcomeBonus[msg.sender] = userWelcomeBonus[msg.sender].sub(amount) : refferalReward[msg.sender] = refferalReward[msg.sender].sub(amount);
    isWelcomebonus ? userWelcomeBonusUsedForLending[msg.sender] = userWelcomeBonusUsedForLending[msg.sender].add(amount) : refferalRewardUsedForLending[msg.sender] = refferalRewardUsedForLending[msg.sender].add(amount);
  e.internalTopup(loanID, amount, msg.sender);
  }

  function setBonuses(uint _welcome, uint _referral) external onlyOwner{
    referralBonus = _referral;
    welcomeBonus = _welcome;
  }

  function returnBonuses() external view returns(uint _referral, uint _welcome){
    return(referralBonus, welcomeBonus);
   }

  function getMyReferrals(address _upline) external view returns(address[] memory _referrals) {
       return  myReferrals[_upline];
    }

  function getMyReferralsCount(address _upline) external view returns(uint _total) {
       return  myReferrals[_upline].length;
    }

 function getUserStats(address _user) external view returns(uint _referral, uint _rUsed, uint _wB, uint _wBUsed) {
       return (refferalReward[_user], refferalRewardUsedForLending[_user], userWelcomeBonus[_user], userWelcomeBonusUsedForLending[_user]);
}


  }