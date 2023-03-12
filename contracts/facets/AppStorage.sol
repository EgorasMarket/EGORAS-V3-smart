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
    bytes _price;
    // needed for swap to work

    //Member ship
    uint256 nextSpillIndex;
    mapping(address => address) referredBy;
    mapping(address => uint256) referralRewardBalance;
    mapping(address => uint256) referralCount;
    mapping(address => bool) alreadyMember;
    uint256 referralBurnBalance;
    mapping(address => bytes) referralLink;
    mapping(bytes => address) referralAddress;
    mapping(bytes => address) token_address;
    mapping(bytes => uint) fee;
    mapping(bytes => bool) isListed;
    mapping(bytes => mapping(address => uint)) liquidity;
}
