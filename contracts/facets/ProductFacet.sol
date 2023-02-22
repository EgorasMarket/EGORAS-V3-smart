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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function mint(address account, uint256 amount) external returns (bool);

    function burnFrom(address account, uint256 amount) external;
}

contract ProductFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint256;
    struct Product {
        string title;
        uint256 amount;
        uint256 selling;
        bool isBidding;
        uint256 latestBid;
        address creator;
        bool tradable;
    }
    Product[] products;

    event ProductCreated(
        string _title,
        uint256 _amount,
        address _creator,
        bool _tradable,
        uint256 _productID,
        uint256 _time
    );
    event Approved(
        uint256 productID,
        address approvedBy,
        uint256 nowSelling,
        uint256 time
    );
    event Bid(
        uint256 _productID,
        uint256 _amount,
        address bidder,
        uint256 time
    );
    event BidAccepted(
        uint256 _productID,
        uint256 _amount,
        address bidder,
        uint256 time
    );
    event Sold(uint256 productID, address buyer, uint256 time);

    modifier onlySystem() {
        require(
            _msgSender() == LibDiamond.contractOwner() ||
                s.pythia[_msgSender()] == true,
            "Access denied, Only system is allowed!"
        );
        _;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function listProduct(string memory _title, uint256 _amount) external {
        require(
            s.member[_msgSender()],
            "You're not a member, please subscribe to any membership plan and try again"
        );
        require(_amount > 0, "Product amount should be greater than zero");
        require(
            bytes(_title).length > 3,
            "Product title should more than three characters long"
        );

        Product memory _product = Product({
            title: _title,
            amount: _amount,
            isBidding: false,
            latestBid: 0,
            selling: _amount,
            creator: _msgSender(),
            tradable: false
        });
        products.push(_product);
        uint256 newProductID = products.length - 1;
        emit ProductCreated(
            _title,
            _amount,
            _msgSender(),
            false,
            newProductID,
            block.timestamp
        );
    }

    function productState(uint256 _productID)
        external
        view
        returns (bool isBidding, uint256 latestBid)
    {
        Product memory p = products[_productID];
        return (p.isBidding, p.latestBid);
    }

    function bid(uint256 _productID, uint256 _amount) external {
        Product storage p = products[_productID];
        require(!p.tradable, "Bidding is over.");
        p.latestBid = _amount;
        p.isBidding = true;
        emit Bid(_productID, _amount, _msgSender(), block.timestamp);
    }

    function acceptBid(uint256 _productID) external {
        Product storage p = products[_productID];
        require(p.creator == _msgSender(), "Unauthorized.");
        require(!p.tradable, "Bidding is over.");
        p.isBidding = false;
        p.amount = p.latestBid;
        emit BidAccepted(
            _productID,
            p.latestBid,
            _msgSender(),
            block.timestamp
        );
    }

    function approveProduct(uint256 _productID) external onlySystem {
        Product storage p = products[_productID];
        require(!p.tradable, "Product is already approved");
        require(!p.isBidding, "Bid not accepted");
        IERC20 eusd = IERC20(s.eusdAddr);
        require(eusd.mint(p.creator, p.amount), "Fail to transfer fund");
        uint256 newProductSellingAmount = p.amount.multiplyDecimal(
            Utils.SALE_PERCENTAGE
        );
        p.selling = p.amount.add(newProductSellingAmount);
        emit Approved(
            _productID,
            _msgSender(),
            p.amount.add(newProductSellingAmount),
            block.timestamp
        );
    }

    function getSelling(uint256 _productID)
        external
        view
        returns (uint256 _sellingAmount)
    {
        Product memory p = products[_productID];
        return (p.selling);
    }

    function isSelling(uint256 _productID)
        external
        view
        returns (bool _isSelling)
    {
        Product memory p = products[_productID];
        return (p.tradable);
    }

    function buyProduct(uint256 _productID) external {
        Product storage p = products[_productID];
        require(p.tradable, "Product is not yet approved/sold");
        IERC20 iERC20 = IERC20(s.eusdAddr);
        require(
            iERC20.allowance(_msgSender(), address(this)) >= p.selling,
            "Insufficient allowance for buyinng!"
        );
        //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
        iERC20.burnFrom(_msgSender(), p.selling);
        p.tradable = false;
        emit Sold(_productID, _msgSender(), block.timestamp);
    }
}
