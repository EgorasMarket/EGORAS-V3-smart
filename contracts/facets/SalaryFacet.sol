// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

contract SalaryFacet {
struct Workers{
    uint salary;
    address account;
    string name;
   }   
  Workers[] workers;
  
 
  function Addworkers(string[] calldata _name, address[] calldata _account, uint[] calldata _salary) external onlyOwner{
    require(_name.length == _account.length, "Invalid parameters");
    require(_salary.length == _account.length, "Invalid parameters");
    for (uint256 i; i < _name.length; i++) {
      
   
        }
  }

modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }  

 function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

// Start of referral system
 function PaySalary() external onlyOwner{
    
    
  }


}