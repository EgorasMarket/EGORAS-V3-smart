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

contract StakingFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    enum Stakinglan {
        MONTHLY,
        ANNUALLY
    }
    event Stake(
        address user,
        uint256 amount,
        uint256 plan,
        uint256 dailyRoyalty,
        uint256 totalRoyalty,
        uint256 time
    );
    event Unstaked(uint256 dueStake, address user, uint256 time);
    event Royalty(address user, uint256 amount, uint256 time);
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

    function unstake() external {
        uint dueStake = s.userTotalStake[_msgSender()];
        uint penalty = s.lockPeriod[_msgSender()] > block.timestamp
            ? s.userTotalStake[_msgSender()].multiplyDecimal(
                Utils.UNSTAKE_PENALTY
            )
            : 0;

        if (penalty > 0) {
            dueStake = s.userTotalStake[_msgSender()].sub(penalty);
        }

        s.userTotalStake[_msgSender()] = 0;
        s.userTotalStakeUsd[_msgSender()] = 0;
        s.dailyRoyalty[_msgSender()] = 0;
        s.lockPeriod[_msgSender()] = block.timestamp.sub(1 days);
        s.nextRoyaltyTakePeriod[_msgSender()] = block.timestamp.sub(2 days);
        IERC20STAKE ierc20 = IERC20STAKE(s.egcAddr);
        require(ierc20.transfer(_msgSender(), dueStake), "Sending faild");

        emit Unstaked(dueStake, _msgSender(), block.timestamp);
    }

    function monthly(uint256 amount) external {
        require(
            s.member[_msgSender()],
            "You're not a member, please subscribe to any membership plan and try again"
        );
        require(amount > 0, "invalid amount");
        uint256 inusd = s.ticker[s.egcusd].multiplyDecimal(amount);
        require(
            inusd >= s.stakingPlan[uint256(Stakinglan.MONTHLY)],
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
        uint256 userCurrentTotal = s.userTotalStakeUsd[_msgSender()].add(inusd);
        s.userTotalStake[_msgSender()] = s.userTotalStake[_msgSender()].add(
            amount
        );
        s.userTotalStakeUsd[_msgSender()] = userCurrentTotal;
        uint256 yearlyRoyalty = userCurrentTotal.multiplyDecimal(
            Utils.YEARLY_INTEREST_RATE
        );
        uint256 dailyInterest = yearlyRoyalty.divideDecimal(
            Utils.DAYS_IN_A_YEAR
        );
        uint256 lockPeriod = block.timestamp.add(30 days);
        uint256 nextRoyaltyTakePeriod = block.timestamp.add(1 days);
        s.dailyRoyalty[_msgSender()] = dailyInterest;
        s.lockPeriod[_msgSender()] = lockPeriod;
        s.nextRoyaltyTakePeriod[_msgSender()] = nextRoyaltyTakePeriod;
        emit Stake(
            _msgSender(),
            amount,
            uint256(Stakinglan.MONTHLY),
            dailyInterest,
            yearlyRoyalty,
            block.timestamp
        );
    }

    function annually(uint256 amount) external {
        require(
            s.member[_msgSender()],
            "You're not a member, please subscribe to any membership plan and try again"
        );
        require(amount > 0, "invalid amount");
        uint256 inusd = s.ticker[s.egcusd].multiplyDecimal(amount);
        require(
            inusd >= s.stakingPlan[uint256(Stakinglan.ANNUALLY)],
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
        uint256 userCurrentTotal = s.userTotalStakeUsd[_msgSender()].add(inusd);
        s.userTotalStake[_msgSender()] = s.userTotalStake[_msgSender()].add(
            amount
        );
        s.userTotalStakeUsd[_msgSender()] = userCurrentTotal;
        uint256 yearlyRoyalty = userCurrentTotal.multiplyDecimal(
            Utils.YEARLY_INTEREST_RATE
        );
        uint256 dailyInterest = yearlyRoyalty.divideDecimal(
            Utils.DAYS_IN_A_YEAR
        );
        uint256 lockPeriod = block.timestamp.add(365 days);
        uint256 nextRoyaltyTakePeriod = block.timestamp.add(1 days);
        s.dailyRoyalty[_msgSender()] = dailyInterest;
        s.lockPeriod[_msgSender()] = lockPeriod;
        s.nextRoyaltyTakePeriod[_msgSender()] = nextRoyaltyTakePeriod;
        emit Stake(
            _msgSender(),
            amount,
            uint256(Stakinglan.ANNUALLY),
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

    function takeRoyalty() external {
        require(
            block.timestamp >= s.nextRoyaltyTakePeriod[_msgSender()],
            "Not yet due!"
        );
        uint256 getNumDays = getDiff(
            s.nextRoyaltyTakePeriod[_msgSender()],
            block.timestamp
        );
        uint256 rolyalty = uint256(
            uint256(s.dailyRoyalty[_msgSender()])
                .divideDecimal(uint256(Utils.DIVISOR_A))
                .multiplyDecimal(uint256(getNumDays > 0 ? getNumDays : 1))
        );
        s.nextRoyaltyTakePeriod[_msgSender()] = block.timestamp.add(1 days);
        IERC20STAKE eusd = IERC20STAKE(s.eusdAddr);
        require(eusd.mint(_msgSender(), rolyalty), "Fail to transfer fund");
        s.totalRoyaltyTaken[_msgSender()] = s
            .totalRoyaltyTaken[_msgSender()]
            .add(rolyalty);

        emit Royalty(_msgSender(), rolyalty, block.timestamp);
    }

    function stakeConfig()
        external
        view
        returns (
            uint256 _YEARLY_INTEREST_RATE,
            uint256 _DAYS_IN_A_YEAR,
            uint256 _egcusd
        )
    {
        return (
            Utils.YEARLY_INTEREST_RATE,
            Utils.DAYS_IN_A_YEAR,
            s.ticker[s.egcusd]
        );
    }

    function royaltyStats(
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
            s.dailyRoyalty[user],
            s.userTotalStake[user],
            s.userTotalStakeUsd[user],
            s.nextRoyaltyTakePeriod[user],
            s.lockPeriod[user],
            s.totalRoyaltyTaken[user],
            Utils.UNSTAKE_PENALTY
        );
    }

    function resetTakeRoyaltyTime(address user) external {
        s.nextRoyaltyTakePeriod[user] = block.timestamp;
    }

    function increaseTakeRoyaltyTime(address user) external {
        s.nextRoyaltyTakePeriod[user] = block.timestamp.sub(4 days);
    }

    function increaseTakeRoyaltyTime2(address user) external {
        s.nextRoyaltyTakePeriod[user] = block.timestamp.sub(2 days);
    }

    function calculateRoyalty(
        address user
    ) external view returns (uint256 _royalty) {
        uint256 getNumDays = getDiff(
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
}
