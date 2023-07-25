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

contract DealersFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;

    enum DealersPlan {
        PLAN_A,
        PLAN_B,
        PLAN_C
    }
    event DealerPlansEdited(
        uint256 _plan_a,
        uint256 _plan_b,
        uint256 _plan_c,
        address _dealerSubcriptionCollector,
        uint256 _time,
        address _msgSender
    );
    event DealerSubscribed(
        address user,
        uint256 amount,
        uint256 expiryDate,
        uint256 plan,
        uint256 time
    );
    event DealerRewarded(address user, uint256 amount, uint256 time);
    event DealerCollectorRewarded(address user, uint256 amount, uint256 time);

    struct Dealers {
        address dealer;
    }
    uint256 private nextSpill;
    Dealers[] dealers;

    uint private totalDealerRefferral;
    uint private totalRewardCollected;

    event DealerReferral(address user, address referredBy, uint time);
    mapping(address => uint256) totalDealerReferralRewardBalance;

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    modifier onlyOwner() {
        require(
            _msgSender() == LibDiamond.contractOwner(),
            "Access denied, Only owner is allowed!"
        );
        _;
    }

    function configureDealersPlan(
        uint256 _plan_a,
        uint256 _plan_b,
        uint256 _plan_c,
        address _token_addres,
        address _dealerSubcriptionCollector
    ) external onlyOwner {
        s.dealersPlan[uint256(DealersPlan.PLAN_A)] = _plan_a;
        s.dealersPlan[uint256(DealersPlan.PLAN_B)] = _plan_b;
        s.dealersPlan[uint256(DealersPlan.PLAN_C)] = _plan_c;
        s._token_addres = _token_addres;
        s.dealerSubcriptionCollector = _dealerSubcriptionCollector;

        emit DealerPlansEdited(
            _plan_a,
            _plan_b,
            _plan_c,
            _dealerSubcriptionCollector,
            block.timestamp,
            _msgSender()
        );
    }

    function becomeADealer(address _dealer, uint256 _dealerPlan) external {
        require(
            block.timestamp >= s.dealerExpiryDate[_dealer],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.dealersPlan[_dealerPlan];
        s.dealerPlan[_dealer] = _dealerPlan;
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(365 days);
        s.dealerExpiryDate[_dealer] = expiryDate;
        s.isADealer[_dealer] = true;
        IERC20 iERC20 = IERC20(s._token_addres);
        require(
            iERC20.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient token allowance for subscription!"
        );
        require(dealerReferralHelper(_dealer, amount), "Referral error");
        require(
            iERC20.transferFrom(_msgSender(), address(this), amount),
            "Fail to transfer"
        );
        emit DealerSubscribed(
            _dealer,
            amount,
            expiryDate,
            _dealerPlan,
            block.timestamp
        );
    }

    function becomeADealerWithReferral(
        address _dealer,
        uint256 _dealerPlan,
        address _referral
    ) external {
        require(
            block.timestamp >= s.dealerExpiryDate[_dealer],
            "Wait until your current plan elapses."
        );
        uint256 amount = s.dealersPlan[_dealerPlan];
        s.dealerPlan[_dealer] = _dealerPlan;
        require(amount > 0, "Invalid plan");
        uint256 expiryDate = block.timestamp.add(365 days);
        s.dealerExpiryDate[_dealer] = expiryDate;
        s.isADealer[_dealer] = true;
        IERC20 iERC20 = IERC20(s._token_addres);
        require(
            iERC20.allowance(_msgSender(), address(this)) >= amount,
            "Insufficient token allowance for subscription!"
        );
        require(
            dealerReferralHelperWithAReferral(_dealer, _referral, amount),
            "Referral error."
        );

        require(
            iERC20.transferFrom(_msgSender(), address(this), amount),
            "Fail to transfer"
        );
        emit DealerSubscribed(
            _dealer,
            amount,
            expiryDate,
            _dealerPlan,
            block.timestamp
        );
    }

    function getPlanPercentage(
        address _dealer
    ) external view returns (uint256) {
        if (s.dealerPlan[_dealer] == uint256(DealersPlan.PLAN_A)) {
            return Utils.PLAN_A_DISCOUNT;
        } else if (s.dealerPlan[_dealer] == uint256(DealersPlan.PLAN_B)) {
            return Utils.PLAN_B_DISCOUNT;
        } else if (s.dealerPlan[_dealer] == uint256(DealersPlan.PLAN_C)) {
            return Utils.PLAN_C_DISCOUNT;
        }

        return 0;
    }

    function getRewardNextSpill() external returns (address) {
        if (dealers.length > 0) {
            if (dealers.length == nextSpill.add(1)) {
                Dealers memory _d = dealers[nextSpill];
                nextSpill = 0;
                return _d.dealer;
            } else if (dealers.length > nextSpill.add(1)) {
                Dealers memory _d = dealers[nextSpill];
                nextSpill = nextSpill.add(1);
                return _d.dealer;
            }
        } else {
            return s.dealerSubcriptionCollector;
        }

        return s.dealerSubcriptionCollector;
    }

    function takeDealerReferralReward(address user) external {
        require(
            s.dealerExpiryDate[user] >= block.timestamp,
            "Renew your dealer plan"
        );
        uint256 amount = s.referralDealerRewardBalance[user];
        s.referralDealerRewardBalance[user] = 0;

        IERC20 iERC20 = IERC20(s._token_addres);

        require(iERC20.transfer(user, amount), "Fail to transfer");
        totalDealerReferralRewardBalance[
            user
        ] = totalDealerReferralRewardBalance[user].add(amount);
        totalDealerRefferral = totalDealerRefferral.add(amount);
        emit DealerRewarded(user, amount, block.timestamp);
    }

    function collectorReward() external {
        uint256 amount = s.dealerSubcriptionCollectorBalance;
        s.dealerSubcriptionCollectorBalance = 0;

        IERC20 iERC20 = IERC20(s._token_addres);

        require(
            iERC20.transfer(s.dealerSubcriptionCollector, amount),
            "Fail to transfer"
        );
        totalRewardCollected = totalRewardCollected.add(amount);

        emit DealerCollectorRewarded(
            s.dealerSubcriptionCollector,
            amount,
            block.timestamp
        );
    }

    function dealerReferralHelper(
        address _user,
        uint256 _amount
    ) internal returns (bool) {
        address _referral = this.getRewardNextSpill();
        uint256 bonus = _amount.multiplyDecimal(Utils.DEALER_REFERRAL_BONUS);

        s.deallerReferredBy[_user] = _referral;
        s.deallerReferralCount[_referral] = s
            .deallerReferralCount[_referral]
            .add(1);
        s.referralDealerRewardBalance[_referral] = s
            .referralDealerRewardBalance[_referral]
            .add(bonus);
        s.dealerSubcriptionCollectorBalance = s
            .dealerSubcriptionCollectorBalance
            .add(_amount.sub(bonus));
        Dealers memory _d = Dealers({dealer: _user});
        dealers.push(_d);

        emit DealerReferral(_user, _referral, block.timestamp);
        return true;
    }

    function dealerReferralHelperWithAReferral(
        address _user,
        address _referral,
        uint256 _amount
    ) internal returns (bool) {
        uint256 bonus = _amount.multiplyDecimal(Utils.REFERRAL_BONUS);
        s.deallerReferredBy[_user] = _referral;
        s.deallerReferralCount[_referral] = s
            .deallerReferralCount[_referral]
            .add(1);
        s.referralDealerRewardBalance[_referral] = s
            .referralDealerRewardBalance[_referral]
            .add(bonus);
        s.dealerSubcriptionCollectorBalance = s
            .dealerSubcriptionCollectorBalance
            .add(_amount.sub(bonus));
        Dealers memory _d = Dealers({dealer: _user});
        dealers.push(_d);
        emit DealerReferral(_user, _referral, block.timestamp);
        return true;
    }

    function dealerReferralStats(
        address user
    )
        external
        view
        returns (uint256 _count, uint256 _amount, uint _totalTaken)
    {
        return (
            s.referralDealerRewardBalance[user],
            s.deallerReferralCount[user],
            totalDealerReferralRewardBalance[user]
        );
    }

    function dealerCollectorStats()
        external
        view
        returns (uint256 _amount, uint _totalTaken)
    {
        return (s.dealerSubcriptionCollectorBalance, totalRewardCollected);
    }
}
