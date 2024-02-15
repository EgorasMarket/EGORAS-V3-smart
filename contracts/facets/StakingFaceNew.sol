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

contract StakingFacetNew {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    enum StakinglanNew {
        MONTHLY,
        ANNUALLY
    }
    event StakeNew(
        address user,
        uint256 amount,
        uint256 plan,
        uint256 dailyRoyalty,
        uint256 totalRoyalty,
        uint256 time
    );
    event UnstakedNew(uint256 dueStake, address user, uint256 time);
    event RoyaltyNew(address user, uint256 amount, uint256 time);
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

    function unstakeNew() external {
        uint dueStake = s.userTotalStakeNew[_msgSender()];

        uint penalty = s.lockPeriodNew[_msgSender()] > block.timestamp
            ? s.userTotalStakeNew[_msgSender()].multiplyDecimal(
                Utils.UNSTAKE_PENALTY
            )
            : 0;

        if (penalty > 0) {
            dueStake = s.userTotalStakeNew[_msgSender()].sub(penalty);
            s.totalPenaltyStakeNew = s.totalPenaltyStakeNew.add(dueStake);
        }
        s.totalUnStakeNew = s.totalUnStakeNew.add(dueStake);
        s.userTotalStakeNew[_msgSender()] = 0;
        s.userTotalStakeEgaxNew[_msgSender()] = 0;
        s.dailyRoyaltyNew[_msgSender()] = 0;
        s.lockPeriodNew[_msgSender()] = block.timestamp.sub(1 days);
        s.nextRoyaltyTakePeriodNew[_msgSender()] = block.timestamp.sub(2 days);
        IERC20STAKE ierc20 = IERC20STAKE(s.egcAddr);
        require(ierc20.transfer(_msgSender(), dueStake), "Sending faild");
        s.member[_msgSender()] = false;
        emit UnstakedNew(dueStake, _msgSender(), block.timestamp);
    }

    function monthlyNew(uint256 amount) external {
        // require(
        //     s.member[_msgSender()],
        //     "You're not a member, please subscribe to any membership plan and try again"
        // );
        require(
            block.timestamp >= s.lockPeriodNew[_msgSender()],
            "Wait until lock period is over!"
        );

        require(amount > 0, "invalid amount");
        uint256 royaltyValue = s.ticker[s.stakeTokenPrice].multiplyDecimal(
            amount
        );
        require(
            royaltyValue >= s.stakingPlanNew[uint256(StakinglanNew.MONTHLY)],
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
        s.totalStakeNew = s.totalStakeNew.add(amount);
        uint256 userCurrentTotal = s.userTotalStakeEgaxNew[_msgSender()].add(
            royaltyValue
        );
        s.userTotalStakeNew[_msgSender()] = s
            .userTotalStakeNew[_msgSender()]
            .add(amount);
        s.userTotalStakeEgaxNew[_msgSender()] = userCurrentTotal;
        uint256 yearlyRoyalty = userCurrentTotal.multiplyDecimal(
            s.yearlyInterest
        );
        uint256 dailyInterest = yearlyRoyalty.divideDecimal(
            Utils.DAYS_IN_A_YEAR
        );
        uint256 lockPeriod = block.timestamp.add(30 days);
        uint256 nextRoyaltyTakePeriod = block.timestamp.add(1 days);
        s.dailyRoyaltyNew[_msgSender()] = dailyInterest;
        s.lockPeriodNew[_msgSender()] = lockPeriod;
        s.nextRoyaltyTakePeriodNew[_msgSender()] = nextRoyaltyTakePeriod;
        s.member[_msgSender()] = true;
        emit StakeNew(
            _msgSender(),
            amount,
            uint256(StakinglanNew.MONTHLY),
            dailyInterest,
            yearlyRoyalty,
            block.timestamp
        );
    }

    function annuallyNew(uint256 amount) external {
        // require(
        //     s.member[_msgSender()],
        //     "You're not a member, please subscribe to any membership plan and try again"
        // );
        require(
            block.timestamp >= s.lockPeriodNew[_msgSender()],
            "Wait until lock period is over!"
        );
        require(amount > 0, "invalid amount");
        uint256 royaltyValue = s.ticker[s.stakeTokenPrice].multiplyDecimal(
            amount
        );

        require(
            royaltyValue >= s.stakingPlanNew[uint256(StakinglanNew.ANNUALLY)],
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
        s.totalStakeNew = s.totalStakeNew.add(amount);
        uint256 userCurrentTotal = s.userTotalStakeEgaxNew[_msgSender()].add(
            royaltyValue
        );
        s.userTotalStakeNew[_msgSender()] = s
            .userTotalStakeNew[_msgSender()]
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
        s.dailyRoyaltyNew[_msgSender()] = dailyInterest;
        s.lockPeriodNew[_msgSender()] = lockPeriod;
        s.nextRoyaltyTakePeriodNew[_msgSender()] = nextRoyaltyTakePeriod;
        s.member[_msgSender()] = true;
        emit StakeNew(
            _msgSender(),
            amount,
            uint256(StakinglanNew.ANNUALLY),
            dailyInterest,
            yearlyRoyalty,
            block.timestamp
        );
    }

    function getDiffNew(
        uint256 start,
        uint256 end
    ) internal pure returns (uint256) {
        uint256 daysDiff = (end - start) /
            Utils.MINUTE_IN_SECONDS /
            Utils.MINUTE_IN_SECONDS /
            Utils.HOUR_IN_DAYS;
        return daysDiff;
    }

    function takeRoyaltyNew() external {
        require(
            block.timestamp >= s.nextRoyaltyTakePeriodNew[_msgSender()],
            "Not yet due!"
        );
        uint256 getNumDays = getDiffNew(
            s.nextRoyaltyTakePeriodNew[_msgSender()],
            block.timestamp
        );
        uint256 rolyalty = uint256(
            uint256(s.dailyRoyaltyNew[_msgSender()])
                .divideDecimal(uint256(Utils.DIVISOR_A))
                .multiplyDecimal(uint256(getNumDays > 0 ? getNumDays : 1))
        );
        s.nextRoyaltyTakePeriodNew[_msgSender()] = block.timestamp.add(1 days);
        IERC20STAKE royaltyToken = IERC20STAKE(s.royaltyAddr);
        require(
            royaltyToken.mint(_msgSender(), rolyalty),
            "Fail to transfer fund"
        );
        s.totalRoyaltyTakenNew[_msgSender()] = s
            .totalRoyaltyTakenNew[_msgSender()]
            .add(rolyalty);

        emit RoyaltyNew(_msgSender(), rolyalty, block.timestamp);
    }

    function totalStakeNew() external view returns (uint256) {
        return (s.totalStake.sub(s.totalUnStake));
    }

    function stakeConfigNew()
        external
        view
        returns (
            uint256 _YEARLY_INTEREST_RATE,
            uint256 _DAYS_IN_A_YEAR,
            uint256 _stakeTokenPrice,
            uint256 _yearlyInterest,
            address _egcAddr
        )
    {
        return (
            Utils.YEARLY_INTEREST_RATE,
            Utils.DAYS_IN_A_YEAR,
            s.ticker[s.stakeTokenPrice],
            s.yearlyInterest,
            s.egcAddr
        );
    }

    function stakeStateNew()
        external
        view
        returns (uint _unStake, uint _totalPenalty, uint _totalStake)
    {
        return (s.totalUnStakeNew, s.totalPenaltyStakeNew, s.totalStakeNew);
    }

    function royaltyStatsNew(
        address user
    )
        external
        view
        returns (
            uint256 _dailyRoyalty,
            uint256 _totalStake,
            uint256 _totalStakeInEgax,
            uint256 _nextRoyaltyTakePeriod,
            uint256 _lockPeriod,
            uint256 _totalRoyaltyTaken,
            uint256 _penalty
        )
    {
        return (
            s.dailyRoyaltyNew[user],
            s.userTotalStakeNew[user],
            s.userTotalStakeEgaxNew[user],
            s.nextRoyaltyTakePeriodNew[user],
            s.lockPeriodNew[user],
            s.totalRoyaltyTakenNew[user],
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

    function calculateRoyaltyNew(
        address user
    ) external view returns (uint256 _royalty) {
        uint256 getNumDays = getDiffNew(
            s.nextRoyaltyTakePeriod[user],
            block.timestamp
        );
        uint256 rolyalty = uint256(
            uint256(s.dailyRoyalty[user])
                .divideDecimal(uint256(Utils.DIVISOR_A))
                .multiplyDecimal(uint256(getNumDays > 0 ? getNumDays : 1))
        );

        return rolyalty;
    }

    function setStakeConfigNew(
        address _egcAddr,
        address _royaltyAddr,
        uint256 _yearlyInterest
    ) external onlyOwner {
        s.egcAddr = _egcAddr;
        s.royaltyAddr = _royaltyAddr;
        s.yearlyInterest = _yearlyInterest;
    }
}
