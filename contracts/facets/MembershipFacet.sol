// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/Utils.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20 {
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

    function burn(uint256 amount) external;
}

contract MembershipFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    enum MembershipPlan {
        MONTHLY,
        SEMIANNUALLY,
        ANNUALLY
    }
    event Subscribed(
        address user,
        uint256 amount,
        uint256 expiryDate,
        uint256 plan,
        uint256 time
    );
    event PlansEdited(
        uint256 _monthly,
        uint256 _semiAnnually,
        uint256 _Annually,
        uint256 time,
        address intiator
    );

    event Rewarded(address user, uint256 amount, uint256 time);
    event Burn(address user, uint256 amount, uint256 time);
    event Referral(address user, address referredBy, uint time);
    struct Members {
        address user;
    }

    Members[] members;

    modifier onlyOwner() {
        require(
            _msgSender() == LibDiamond.contractOwner(),
            "Access denied, Only owner is allowed!"
        );
        _;
    }
    uint private totalBurnAmount = 0;
    uint private totalRefferral = 0;

    mapping(address => uint256) totalReferralRewardBalance;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function configurePlan(
        uint256 _monthlyPrice,
        uint256 _semiAnnuallyPlan,
        uint256 _annuallyPlan,
        address _egc,
        address _eusd
    ) external onlyOwner {
        s.plan[uint256(MembershipPlan.MONTHLY)] = _monthlyPrice;
        s.plan[uint256(MembershipPlan.SEMIANNUALLY)] = _semiAnnuallyPlan;
        s.plan[uint256(MembershipPlan.ANNUALLY)] = _annuallyPlan;
        s.egcAddr = _egc;
        s.eusdAddr = _eusd;
        emit PlansEdited(
            _monthlyPrice,
            _semiAnnuallyPlan,
            _annuallyPlan,
            block.timestamp,
            _msgSender()
        );
    }

    function getAddresses()
        external
        view
        returns (address _egc, address _eusd)
    {
        return (s.egcAddr, s.eusdAddr);
    }

    function getConfiguration()
        external
        view
        returns (uint256 _monthly, uint256 _semiAnnually, uint256 _annually)
    {
        return (
            s.plan[uint256(MembershipPlan.MONTHLY)],
            s.plan[uint256(MembershipPlan.SEMIANNUALLY)],
            s.plan[uint256(MembershipPlan.ANNUALLY)]
        );
    }

    function membershipMonthlyPlan(address user) external {
        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.MONTHLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(30 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.SEMIANNUALLY)
            ),
            "Unable to subscribe"
        );

        require(referralHelper(user, amount), "Referral error");
    }

    function monthlyPlanWithReferral(address user, address _referral) external {
        require(s.alreadyMember[_referral], "Invalid referral address.");

        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );

        uint256 amount = s.plan[uint256(MembershipPlan.MONTHLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(30 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.SEMIANNUALLY)
            ),
            "Unable to subscribe"
        );
        require(
            referralWithReferralHelper(user, _referral, amount),
            "Referral error."
        );
    }

    function semiAnnuallyPlanWithReferral(
        address user,
        address _referral
    ) external {
        require(s.alreadyMember[_referral], "Invalid referral address.");

        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.SEMIANNUALLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(180 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.SEMIANNUALLY)
            ),
            "Unable to subscribe"
        );

        require(
            referralWithReferralHelper(user, _referral, amount),
            "Referral error."
        );
    }

    function membershipSemiAnnuallyPlan(address user) external {
        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.SEMIANNUALLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(180 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.SEMIANNUALLY)
            ),
            "Unable to subscribe"
        );

        require(referralHelper(user, amount), "Referral error");
    }

    function annuallyWithReferral(address user, address _referral) external {
        require(s.alreadyMember[_referral], "Invalid referral address.");

        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.ANNUALLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(365 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.ANNUALLY)
            ),
            "Unable to subscribe"
        );

        require(
            referralWithReferralHelper(user, _referral, amount),
            "Referral error."
        );
    }

    function membershipAnnually(address user) external {
        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.ANNUALLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(365 days);

        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.ANNUALLY)
            ),
            "Unable to subscribe"
        );
        require(referralHelper(user, amount), "Referral error");
    }

    function subscribe(
        uint256 _amount,
        address _user,
        uint256 _expiryDate,
        uint256 plan
    ) internal returns (bool) {
        s.expiryDate[_user] = _expiryDate;
        s.member[_user] = true;
        IERC20 iERC20 = IERC20(s.egcAddr);
        require(
            iERC20.allowance(_msgSender(), address(this)) >= _amount,
            "Insufficient EGC allowance for subscription!"
        );
        require(
            iERC20.transferFrom(_msgSender(), address(this), _amount),
            "Fail to transfer"
        );

        emit Subscribed(_user, _amount, _expiryDate, plan, block.timestamp);
        return true;
    }

    function referralHelper(
        address _user,
        uint256 _amount
    ) internal returns (bool) {
        // require(
        //     !s.alreadyMember[_msgSender()],
        //     "You can only renew your plan."
        // );
        address _referral = this.getNextSpill();
        // require(
        //     address(0) != _referral,
        //     "Invalid address. Address zero was returned."
        // );
        uint256 bonus = _amount.multiplyDecimal(Utils.REFERRAL_BONUS);
        s.referredBy[_user] = _referral;
        s.referralCount[_referral] = s.referralCount[_referral].add(1);
        s.referralRewardBalance[_referral] = s
            .referralRewardBalance[_referral]
            .add(bonus);
        s.referralBurnBalance = s.referralBurnBalance.add(_amount.sub(bonus));
        Members memory _m = Members({user: _user});
        members.push(_m);
        s.alreadyMember[_user] = true;
        emit Referral(_user, _referral, block.timestamp);
        return true;
    }

    function referralWithReferralHelper(
        address _user,
        address _referral,
        uint256 _amount
    ) internal returns (bool) {
        // require(
        //     !s.alreadyMember[_msgSender()],
        //     "You can only renew your plan."
        // );
        uint256 bonus = _amount.multiplyDecimal(Utils.REFERRAL_BONUS);
        s.referredBy[_user] = _referral;
        s.referralCount[_referral] = s.referralCount[_referral].add(1);
        s.referralRewardBalance[_referral] = s
            .referralRewardBalance[_referral]
            .add(bonus);
        s.referralBurnBalance = s.referralBurnBalance.add(_amount.sub(bonus));
        Members memory _m = Members({user: _user});
        members.push(_m);
        s.alreadyMember[_user] = true;
        emit Referral(_user, _referral, block.timestamp);
        return true;
    }

    function renewMonthlyMembership(address user) external {
        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.MONTHLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(30 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.MONTHLY)
            ),
            "Unable to subscribe"
        );

        require(
            referralWithReferralHelper(user, s.referredBy[user], amount),
            "Referral error."
        );
    }

    function renewSemiAnnualMembership(address user) external {
        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.SEMIANNUALLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(180 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.SEMIANNUALLY)
            ),
            "Unable to subscribe"
        );

        require(
            referralWithReferralHelper(
                user,
                s.referredBy[_msgSender()],
                amount
            ),
            "Referral error."
        );
    }

    function renewAnnualMembership(address user) external {
        require(
            block.timestamp >= s.expiryDate[user],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.plan[uint256(MembershipPlan.ANNUALLY)];
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(365 days);
        require(
            subscribe(
                amount,
                user,
                expiryDate,
                uint256(MembershipPlan.ANNUALLY)
            ),
            "Unable to subscribe"
        );

        require(
            referralWithReferralHelper(user, s.referredBy[user], amount),
            "Referral error."
        );
    }

    function takeReferralReward(address user) external {
        require(
            s.expiryDate[user] >= block.timestamp,
            "Renew your membership plan"
        );
        uint256 amount = s.referralRewardBalance[user];
        s.referralRewardBalance[user] = 0;

        IERC20 iERC20 = IERC20(s.egcAddr);

        require(iERC20.transfer(user, amount), "Fail to transfer");
        totalReferralRewardBalance[user] = totalReferralRewardBalance[user].add(
            amount
        );
        totalRefferral = totalRefferral.add(amount);
        emit Rewarded(user, amount, block.timestamp);
    }

    function burn() external {
        uint256 amount = s.referralBurnBalance;
        s.referralBurnBalance = 0;
        IERC20 iERC20 = IERC20(s.egcAddr);

        iERC20.burn(amount);
        totalBurnAmount = totalBurnAmount.add(amount);
        emit Burn(_msgSender(), amount, block.timestamp);
    }

    function getBurnableAmount() external view returns (uint) {
        return s.referralBurnBalance;
    }

    function totalBurn() external view returns (uint) {
        return totalBurnAmount;
    }

    function referredBy(
        address user
    ) external view returns (address referralAddress) {
        return s.referredBy[user];
    }

    function referralStats(
        address user
    )
        external
        view
        returns (uint256 _count, uint256 _amount, uint _totalTaken)
    {
        return (
            s.referralRewardBalance[user],
            s.referralCount[user],
            totalReferralRewardBalance[user]
        );
    }

    function getNextSpill() external returns (address) {
        if (members.length == (s.nextSpillIndex + 1)) {
            Members memory _m = members[s.nextSpillIndex];
            s.nextSpillIndex = 0;
            return _m.user;
        } else if (members.length > (s.nextSpillIndex + 1)) {
            Members memory _m = members[s.nextSpillIndex];
            s.nextSpillIndex = s.nextSpillIndex.add(1);

            return _m.user;
        } else {
            return address(this);
        }
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    function isAMember(address user) external view returns (bool) {
        return s.member[user];
    }

    function getMembersLength() external view returns (uint) {
        return members.length;
    }

    function getMember(uint index) external view returns (address) {
        Members memory _m = members[index];
        return _m.user;
    }
}
