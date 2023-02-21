// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct AppStorage {
    mapping(bytes => uint256) ticker;
    mapping(address => bool) pythia;
    mapping(address => address[]) myReferrals;
    mapping(address => uint256) staffId;
    address eusdAddr;
    address egcAddr;
    bytes egcusd;
    mapping(address => bool) member;
    mapping(uint256 => uint256) plan;
    mapping(uint256 => uint256) stakingPlan;
    mapping(address => uint256) expiryDate;
    mapping(address => uint256) userTotalStake;
    mapping(address => uint256) userTotalStakeUsd;
    mapping(address => uint256) dailyRoyalty;
    mapping(address => uint256) lockPeriod;
    mapping(address => uint256) nextRoyaltyTakePeriod;
    mapping(address => uint256) totalRoyaltyTaken;
    mapping(address => mapping(bool => uint256)) userTotalSwap;
    mapping(bool => uint256) totalSwap;
    // needed for swap to work
    address _priceOracle;
    address _baseAddress;
    address _tokenAddress;
    bytes _price;
    // needed for swap to work
}
