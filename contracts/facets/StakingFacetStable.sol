// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/Utils.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20STAKE {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external;
}

contract StakingFacetStable {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    enum StakinglanStable {
        MONTHLY,
        ANNUALLY
    }
    event StakeStable(
        address user,
        uint256 amount,
        uint256 plan,
        uint256 dailyRoyalty,
        uint256 totalRoyalty,
        uint256 time
    );
    event UnstakedStable(uint256 dueStake, address user, uint256 time);
    event RoyaltyStable(address user, uint256 amount, uint256 time);
    modifier onlyOwner() {
        require(
            _msgSender() == LibDiamond.contractOwner(),
            "Access denied, Only owner is allowed!"
        );
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function unstakeStable() external {
        uint dueStake = s.userTotalStakeStable[_msgSender()];

        uint penalty = s.lockPeriodStable[_msgSender()] > block.timestamp
            ? s.userTotalStakeStable[_msgSender()].multiplyDecimal(
                Utils.UNSTAKE_PENALTY
            )
            : 0;

        if (penalty > 0) {
            dueStake = s.userTotalStakeStable[_msgSender()].sub(penalty);
            s.totalPenaltyStakeStable = s.totalPenaltyStakeStable.add(dueStake);
        }
        s.totalUnStakeStable = s.totalUnStakeStable.add(dueStake);
        s.userTotalStakeStable[_msgSender()] = 0;
        s.userTotalStakeUsdStable[_msgSender()] = 0;
        s.dailyRoyaltyStable[_msgSender()] = 0;
        s.lockPeriodStable[_msgSender()] = block.timestamp.sub(1 days);
        s.nextRoyaltyTakePeriodStable[_msgSender()] = block.timestamp.sub(
            2 days
        );
        IERC20STAKE ierc20 = IERC20STAKE(s.eusdAddr);
        require(ierc20.transfer(_msgSender(), dueStake), "Sending faild");
        s.member[_msgSender()] = false;
        emit UnstakedStable(dueStake, _msgSender(), block.timestamp);
    }

    function monthlyStable(uint256 amount) external {
        // require(
        //     s.member[_msgSender()],
        //     "You're not a member, please subscribe to any membership plan and try again"
        // );
        require(
            block.timestamp >= s.lockPeriod[_msgSender()],
            "Wait until lock period is over!"
        );

        require(amount > 0, "invalid amount");
        uint256 inusd = amount;
        require(
            inusd >= s.stakingPlanStable[uint256(StakinglanStable.MONTHLY)],
            "Please increase your staking amount."
        );
        IERC20STAKE iERC20 = IERC20STAKE(s.eusdAddr);
        require(
            iERC20.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient EGC allowance for staking!"
        );
        require(
            iERC20.transferFrom(_msgSender(), address(this), amount),
            "Error!"
        );
        s.totalStakeStable = s.totalStakeStable.add(amount);
        uint256 userCurrentTotal = s.userTotalStakeUsdStable[_msgSender()].add(
            inusd
        );
        s.userTotalStakeStable[_msgSender()] = s
            .userTotalStakeStable[_msgSender()]
            .add(amount);
        s.userTotalStakeUsdStable[_msgSender()] = userCurrentTotal;
        uint256 yearlyRoyalty = userCurrentTotal.multiplyDecimal(
            s.yearlyInterest
        );
        uint256 dailyInterest = yearlyRoyalty.divideDecimal(
            Utils.DAYS_IN_A_YEAR
        );
        uint256 lockPeriod = block.timestamp.add(30 days);
        uint256 nextRoyaltyTakePeriod = block.timestamp.add(1 days);
        s.dailyRoyaltyStable[_msgSender()] = dailyInterest;
        s.lockPeriodStable[_msgSender()] = lockPeriod;
        s.nextRoyaltyTakePeriodStable[_msgSender()] = nextRoyaltyTakePeriod;
        s.member[_msgSender()] = true;
        emit StakeStable(
            _msgSender(),
            amount,
            uint256(StakinglanStable.MONTHLY),
            dailyInterest,
            yearlyRoyalty,
            block.timestamp
        );
    }

    function annuallyStable(uint256 amount) external {
        // require(
        //     s.member[_msgSender()],
        //     "You're not a member, please subscribe to any membership plan and try again"
        // );
        require(
            block.timestamp >= s.lockPeriodStable[_msgSender()],
            "Wait until lock period is over!"
        );
        require(amount > 0, "invalid amount");
        uint256 inusd = amount;

        require(
            inusd >= s.stakingPlanStable[uint256(StakinglanStable.ANNUALLY)],
            "Please increase your staking amount."
        );
        IERC20STAKE iERC20 = IERC20STAKE(s.egcAddr);
        require(
            iERC20.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient EGC allowance for staking!"
        );
        require(
            iERC20.transferFrom(_msgSender(), address(this), amount),
            "Error!"
        );
        s.totalStakeStable = s.totalStakeStable.add(amount);
        uint256 userCurrentTotal = s.userTotalStakeUsdStable[_msgSender()].add(
            inusd
        );
        s.userTotalStakeStable[_msgSender()] = s
            .userTotalStakeStable[_msgSender()]
            .add(amount);
        s.userTotalStakeUsd[_msgSender()] = userCurrentTotal;
        uint256 yearlyRoyalty = userCurrentTotal.multiplyDecimal(
            s.yearlyInterest
        );
        uint256 dailyInterest = yearlyRoyalty.divideDecimal(
            Utils.DAYS_IN_A_YEAR
        );
        uint256 lockPeriod = block.timestamp.add(365 days);
        uint256 nextRoyaltyTakePeriod = block.timestamp.add(1 days);
        s.dailyRoyaltyStable[_msgSender()] = dailyInterest;
        s.lockPeriodStable[_msgSender()] = lockPeriod;
        s.nextRoyaltyTakePeriodStable[_msgSender()] = nextRoyaltyTakePeriod;
        s.member[_msgSender()] = true;
        emit StakeStable(
            _msgSender(),
            amount,
            uint256(StakinglanStable.ANNUALLY),
            dailyInterest,
            yearlyRoyalty,
            block.timestamp
        );
    }

    function getDiff(
        uint256 start,
        uint256 end
    ) internal pure returns (uint256) {
        uint256 daysDiff = (end - start) /
            Utils.MINUTE_IN_SECONDS /
            Utils.MINUTE_IN_SECONDS /
            Utils.HOUR_IN_DAYS;
        return daysDiff;
    }

    function takeRoyaltyStable() external {
        require(
            block.timestamp >= s.nextRoyaltyTakePeriodStable[_msgSender()],
            "Not yet due!"
        );
        uint256 getNumDays = getDiff(
            s.nextRoyaltyTakePeriodStable[_msgSender()],
            block.timestamp
        );
        uint256 rolyalty = uint256(
            uint256(s.dailyRoyaltyStable[_msgSender()])
                .divideDecimal(uint256(Utils.DIVISOR_A))
                .multiplyDecimal(uint256(getNumDays > 0 ? getNumDays : 1))
        );
        s.nextRoyaltyTakePeriodStable[_msgSender()] = block.timestamp.add(
            1 days
        );
        IERC20STAKE eusd = IERC20STAKE(s.eusdAddr);
        require(eusd.mint(_msgSender(), rolyalty), "Fail to transfer fund");
        s.totalRoyaltyTakenStable[_msgSender()] = s
            .totalRoyaltyTakenStable[_msgSender()]
            .add(rolyalty);

        emit RoyaltyStable(_msgSender(), rolyalty, block.timestamp);
    }

    function totalStakeStable() external view returns (uint256) {
        return (s.totalStakeStable.sub(s.totalUnStakeStable));
    }

    function stakeConfigStable()
        external
        view
        returns (
            uint256 _YEARLY_INTEREST_RATE,
            uint256 _DAYS_IN_A_YEAR,
            uint256 _yearlyInterest
        )
    {
        return (
            Utils.YEARLY_INTEREST_RATE,
            Utils.DAYS_IN_A_YEAR,
            s.yearlyInterest
        );
    }

    function stakeStateStable()
        external
        view
        returns (uint _unStake, uint _totalPenalty, uint _totalStake)
    {
        return (
            s.totalUnStakeStable,
            s.totalPenaltyStakeStable,
            s.totalStakeStable
        );
    }

    function royaltyStatsStable(
        address user
    )
        external
        view
        returns (
            uint256 _dailyRoyalty,
            uint256 _totalStake,
            uint256 _totalStakeUSD,
            uint256 _nextRoyaltyTakePeriod,
            uint256 _lockPeriod,
            uint256 _totalRoyaltyTaken,
            uint256 _penalty
        )
    {
        return (
            s.dailyRoyaltyStable[user],
            s.userTotalStakeStable[user],
            s.userTotalStakeUsdStable[user],
            s.nextRoyaltyTakePeriodStable[user],
            s.lockPeriodStable[user],
            s.totalRoyaltyTakenStable[user],
            Utils.UNSTAKE_PENALTY
        );
    }

    // function resetTakeRoyaltyTime(address user) external {
    //     s.nextRoyaltyTakePeriod[user] = block.timestamp;
    // }

    // function increaseTakeRoyaltyTime(address user) external {
    //     s.nextRoyaltyTakePeriod[user] = block.timestamp.sub(4 days);
    // }

    // function increaseTakeRoyaltyTime2(address user) external {
    //     s.nextRoyaltyTakePeriod[user] = block.timestamp.sub(2 days);
    // }

    function calculateRoyaltyStable(
        address user
    ) external view returns (uint256 _royalty) {
        uint256 getNumDays = getDiff(
            s.nextRoyaltyTakePeriodStable[user],
            block.timestamp
        );
        uint256 rolyalty = uint256(
            uint256(s.dailyRoyaltyStable[user])
                .divideDecimal(uint256(Utils.DIVISOR_A))
                .multiplyDecimal(uint256(getNumDays > 0 ? getNumDays : 1))
        );

        return rolyalty;
    }

    function setStakeConfigStable(
        address _eusdAddr,
        uint256 _yearlyInterest
    ) external onlyOwner {
        s.eusdAddr = _eusdAddr;
        s.yearlyInterest = _yearlyInterest;
    }
}
