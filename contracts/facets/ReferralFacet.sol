// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./AppStorage.sol";

contract ReferralFacet {

AppStorage internal s;

modifier onlyRPythia{
        require(s.pythia[msg.sender], "Access denied. Only Pythia is allowed!");
        _;
    }

// Start of referral system
 function kycUsers(address[] calldata _users, address[] calldata _upline) external onlyRPythia{
    require(_users.length == _upline.length, "Users and Upline must be of equal length");
    for (uint256 i; i < _users.length; i++) {
    
   
        }
  }

}