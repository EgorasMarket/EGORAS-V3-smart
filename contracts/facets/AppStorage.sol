// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct AppStorage {
  mapping (bytes=>uint) ticker;
  mapping (address=>bool)  pythia;
  mapping(address => address[]) myReferrals;
  mapping(address => uint) staffId;
  address eusdAddr;
  address egcAddr;
  bytes egcusd;
  mapping(address => bool) member;
  mapping(uint => uint) plan;
  mapping(uint => uint) stakingPlan;
  mapping(address => uint) expiryDate;
  mapping(address => uint) userTotalStake;
  mapping(address => uint) userTotalStakeUsd;
  mapping(address => uint) dailyRoyalty;
  mapping(address => uint) lockPeriod;
  mapping(address => uint) nextRoyaltyTakePeriod;
  mapping(address => uint) totalRoyaltyTaken;

  

}