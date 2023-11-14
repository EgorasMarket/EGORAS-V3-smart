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
    mapping(uint => mapping(uint => uint)) soldProductAmount;
    mapping(uint => mapping(uint => address)) soldProductBuyer;
    uint totalStake;
    uint totalPenaltyStake;
    uint totalUnStake;
    uint initProductCount;
    mapping(uint => mapping(address => uint)) userActivity;
    mapping(address => uint) allUserActivity;
    mapping(uint => uint) currentAllActivity;
    uint allActivity;
    uint rewardPeriod;
    uint nextRewardPeriod;
    mapping(uint => mapping(address => bool)) currentPerfomers;
    uint totalRewardTokenRemaining;
    uint totalRewardDistributed;
    mapping(address => uint) userTotalRewardRecieved;
    mapping(address => uint) lockedRewardForStaking;
    uint stakingPlanForSixMonths;
    mapping(uint256 => uint256) dealersPlan;
    address _token_addres;
    mapping(address => uint256) dealerExpiryDate;
    mapping(address => bool) isADealer;
    mapping(address => uint256) dealerPlan;
    address dealerSubcriptionCollector;
    mapping(address => uint256) referralDealerRewardBalance;
    uint256 dealerSubcriptionCollectorBalance;
    mapping(address => address) deallerReferredBy;
    mapping(address => uint256) deallerReferralCount;
    bytes naira;
    uint256 totalProcurementAmount;
    mapping(uint256 => uint256) yesVotes;
    mapping(uint256 => uint256) noVotes;
    mapping(uint256 => uint256) vottingPeriod;
    mapping(address => mapping(uint256 => bool)) hasVoted;
}
