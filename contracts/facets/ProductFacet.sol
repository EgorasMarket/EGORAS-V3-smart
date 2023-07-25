// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/Utils.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";
import "./ERC721.sol";
import "../extensions/ERC721URIStorage.sol";
import "../access/AccessControl.sol";
import "../utils/Counters.sol";

interface GETADDRESSES {
    function getAddresses() external view returns (address, address);

    function isPythia(address _pythia) external view returns (bool);

    function isAMember(address user) external view returns (bool);

    function recordUserActivity(address user, uint256 amount) external;
}

interface IERC20PRODUCTINTERFACE {
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

    function totalStake() external view returns (uint256);

    function getStakingAndBuyingTokenPrices()
        external
        view
        returns (uint256, uint256);

    function getPlanPercentage(address _dealer) external view returns (uint256);
}

contract ProductFacet is ERC721, ERC721URIStorage {
    AppStorage internal s;
    using SafeMath for uint256;
    using Strings for uint256;
    using SafeDecimalMath for uint256;
    struct Product {
        uint256 id;
        string title;
        uint256 amount;
        uint256 selling;
        bool isBidding;
        uint256 latestBid;
        address creator;
        bool tradable;
        uint qty;
        bool isdirect;
        bool isApprove;
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

    event DirectProductCreated(
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

    event ProductApproved(uint256 _productID, uint256 time);
    event Sold(
        uint256 productID,
        uint qty,
        uint soldProductCounter,
        address buyer,
        uint256 time
    );
    event TradeCanceled(uint _productID, uint tradeID, uint time);

    event NFTMinted(uint256 productID, uint256 tokenID, uint256 time);
    event ReleaseProductFundToSeller(
        uint256 _productID,
        uint256 tradeID,
        uint256 time
    );
    uint private noneMemberFee;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _productCounter;
    Counters.Counter private _soldProductCounter;

    event Sales(
        uint256 productID,
        uint qty,
        uint soldProductCounter,
        address buyer,
        uint discount,
        uint256 time
    );
    event ProcurementPriceUpdate(
        uint256 productID,
        uint selling,
        uint procurementPrice,
        address initiator,
        uint256 time
    );

    // function setupNFT(
    //     string memory _nftName,
    //     string memory _nftSymbol
    // ) external onlySystem {
    //     setConstructor(_nftName, _nftSymbol);
    // }

    function _baseURI() internal pure override returns (string memory) {
        return "https://egoras-v3-staging.egoras.com/product/nft/product/by/";
    }

    function safeMint(string memory uri, uint _productID) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(LibDiamond.contractOwner(), tokenId);
        _setTokenURI(tokenId, uri);
        emit NFTMinted(_productID, tokenId, block.timestamp);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return "Egoras Market NFT";
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return "EMN";
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public pure override(ERC721, ERC721URIStorage) returns (string memory) {
        return string(abi.encodePacked(_baseURI(), tokenId.toString()));
    }

    function isSystem() internal view returns (bool) {
        GETADDRESSES getAddress = GETADDRESSES(address(this));
        if (
            LibDiamond.contractOwner() == _msgSender() ||
            getAddress.isPythia(_msgSender())
        ) {
            return true;
        }
        return false;
    }

    function checkProcurementLimit(uint _amount) internal view returns (bool) {
        IERC20PRODUCTINTERFACE procurementLimit = IERC20PRODUCTINTERFACE(
            address(this)
        );
        (uint256 nairaDollarPrice, uint256 egcDollarPrice) = procurementLimit
            .getStakingAndBuyingTokenPrices();
        uint256 totalStake = procurementLimit.totalStake();
        uint256 totalStakedEGCInUSD = egcDollarPrice.multiplyDecimal(
            totalStake
        );
        uint256 totalProcurementInUSD = nairaDollarPrice.multiplyDecimal(
            s.totalProcurementAmount.add(_amount)
        );

        if (totalProcurementInUSD > totalStakedEGCInUSD) {
            return true;
        }

        return false;
    }

    // amount minting price // amount of minting price to send to procurer

    // sell price

    function Procurement(
        string memory _title,
        uint256 _amount,
        uint256 _sellingPrice,
        uint256 _qty
    ) external {
        require(_amount > 0, "Product amount should be greater than zero");
        require(_qty > 0, "Product quantity should be greater than zero");
        require(
            bytes(_title).length > 3,
            "Product title should more than three characters long"
        );
        uint256 productID = _productCounter.current();
        _productCounter.increment();
        Product memory _product = Product({
            id: productID,
            title: _title,
            amount: _amount,
            isBidding: false,
            latestBid: 0,
            selling: _sellingPrice,
            creator: _msgSender(),
            tradable: false,
            qty: _qty,
            isdirect: false,
            isApprove: false
        });
        products.push(_product);
        uint newProductID = products.length - 1;

        emit ProductCreated(
            _title,
            _amount,
            _msgSender(),
            false,
            newProductID,
            block.timestamp
        );
    }

    function _mintNft(uint _productID, uint _qty) internal {
        for (uint i = 0; i < _qty; i++) {
            safeMint(_baseURI(), _productID);
        }
    }

    function productState(
        uint256 _productID
    )
        external
        view
        returns (
            bool isBidding,
            uint256 latestBid,
            address _creator,
            uint256 _amount,
            uint256 _selling,
            address eusd
        )
    {
        Product memory p = products[_productID];
        return (
            p.isBidding,
            p.latestBid,
            p.creator,
            p.amount,
            p.selling,
            s.eusdAddr
        );
    }

    // function bid(uint256 _productID, uint256 _amount) external {
    //     Product storage p = products[_productID];
    //     require(!p.isdirect, "Invalid product type.");
    //     require(!p.tradable, "Bidding is over.");
    //     p.latestBid = _amount;
    //     p.isBidding = true;
    //     emit Bid(_productID, _amount, _msgSender(), block.timestamp);
    // }

    //approveDirectProduct
    // function procure(uint256 _productID) external {
    //     Product storage p = products[_productID];

    //     require(isSystem(), "Access denied. You don't have access to upload!");
    //     require(!p.isApprove, "Already approved.");
    //     require(p.isdirect, "Invalid product type.");
    //     p.isApprove = true;

    //     _mintNft(_productID, p.qty);

    //     emit ProductApproved(_productID, block.timestamp);
    // }

    // function acceptBid(uint256 _productID) external {
    //     Product storage p = products[_productID];
    //     require(p.creator == _msgSender(), "Unauthorized.");
    //     require(!p.tradable, "Bidding is over.");
    //     p.isBidding = false;
    //     p.amount = p.latestBid;
    //     emit BidAccepted(
    //         _productID,
    //         p.latestBid,
    //         _msgSender(),
    //         block.timestamp
    //     );
    // }

    // function setNetworkFeeIfNotMember(uint _fee) external {
    //     require(isSystem(), "Access denied. You don't have access to upload!");
    //     noneMemberFee = _fee;
    // }

    // function getNetworkFeeIfNotMember() external view returns (uint) {
    //     return noneMemberFee > 0 ? noneMemberFee : 100000000000000000;
    // }

    // function addNetworkFeeIfNotMember(
    //     address _user,
    //     uint _amount
    // ) internal view returns (uint) {
    //     GETADDRESSES getAddress = GETADDRESSES(address(this));
    //     if (getAddress.isAMember(_user) == false) {
    //         uint fee = noneMemberFee > 0 ? noneMemberFee : 100000000000000000;
    //         return _amount.multiplyDecimal(fee);
    //     }

    //     return 0;
    // }
    function updateProcurementPrice(
        uint256 _productID,
        uint256 _sellingPrice,
        uint256 _procurementPrice
    ) external {
        Product storage p = products[_productID];
        p.amount = _procurementPrice;
        p.selling = _sellingPrice;
        emit ProcurementPriceUpdate(
            _productID,
            _sellingPrice,
            _procurementPrice,
            _msgSender(),
            block.timestamp
        );
    }

    function procurementAuthorized(uint256 _productID) external {
        Product storage p = products[_productID];
        uint256 total = p
            .amount
            .divideDecimal(uint256(Utils.DIVISOR_A))
            .multiplyDecimal(p.qty);
        require(isSystem(), "Access denied. You don't have access to upload!");
        require(!p.tradable, "Product is already approved");
        require(!p.isdirect, "Invalid product type.");
        require(
            !checkProcurementLimit(total),
            "Procurement limit reached. Try increasing staking!"
        );
        p.tradable = true;

        // uint256 newProductSellingAmount = p.amount.multiplyDecimal(
        //     Utils.SALE_PERCENTAGE
        // );
        // p.selling = p.amount.add(newProductSellingAmount);
        _mintNft(_productID, p.qty);
        s.totalProcurementAmount = s.totalProcurementAmount.add(p.amount);
        require(send(p.creator, total, 0, false), "Unable to transfer money!");

        emit Approved(_productID, _msgSender(), p.amount, block.timestamp);
    }

    // function getSelling(
    //     uint256 _productID
    // ) external view returns (uint256 _sellingAmount) {
    //     Product memory p = products[_productID];
    //     return (p.selling);
    // }

    // function isSelling(
    //     uint256 _productID
    // ) external view returns (bool _isSelling) {
    //     Product memory p = products[_productID];
    //     return (p.tradable);
    // }

    function purchase(address user, uint256 _productID, uint qty) external {
        GETADDRESSES setRecord = GETADDRESSES(address(this));
        Product storage p = products[_productID];
        uint256 soldProductCounter = _soldProductCounter.current();
        require(p.qty >= qty, "Product is out of stock!");
        require(!p.isdirect, "Invalid product type.");
        require(p.tradable, "Product is not yet approved/sold");
        s.soldProductAmount[_productID][soldProductCounter] = p
            .selling
            .divideDecimal(uint256(Utils.DIVISOR_A))
            .multiplyDecimal(qty);
        s.soldProductBuyer[_productID][soldProductCounter] = user;
        setRecord.recordUserActivity(user, p.amount.multiplyDecimal(p.qty));
        p.qty = p.qty.sub(qty);
        _soldProductCounter.increment();
        uint256 discount = giveDiscountIfIsADealer(user, p.selling);
        require(
            send(user, p.selling.sub(discount), qty, true),
            "Unable to transfer money!"
        );
        emit Sales(
            _productID,
            qty,
            soldProductCounter,
            user,
            discount,
            block.timestamp
        );
    }

    function giveDiscountIfIsADealer(
        address user,
        uint256 amount
    ) internal view returns (uint256) {
        IERC20PRODUCTINTERFACE getDiscount = IERC20PRODUCTINTERFACE(
            address(this)
        );
        return amount.multiplyDecimal(getDiscount.getPlanPercentage(user));
    }

    // function buyDirectProduct(
    //     address user,
    //     uint256 _productID,
    //     uint qty
    // ) external {
    //     GETADDRESSES setRecord = GETADDRESSES(address(this));
    //     Product storage p = products[_productID];
    //     uint256 soldProductCounter = _soldProductCounter.current();
    //     require(p.isdirect, "Invalid product type.");
    //     require(p.isApprove, "This product is not approved.");
    //     require(p.qty >= qty, "Product is out of stock!");
    //     s.soldProductAmount[_productID][soldProductCounter] = p
    //         .selling
    //         .divideDecimal(uint256(Utils.DIVISOR_A))
    //         .multiplyDecimal(qty);
    //     s.soldProductBuyer[_productID][soldProductCounter] = user;
    //     p.qty = p.qty.sub(qty);
    //     setRecord.recordUserActivity(user, p.amount.multiplyDecimal(p.qty));
    //     _soldProductCounter.increment();
    //     require(
    //         send(
    //             user,
    //             p.amount.add(addNetworkFeeIfNotMember(user, p.amount)),
    //             qty,
    //             true
    //         ),
    //         "Unable to transfer money!"
    //     );
    //     emit Sold(_productID, qty, soldProductCounter, user, block.timestamp);
    // }

    // function cancelTrade(uint256 _productID, uint tradeID) external {
    //     Product memory p = products[_productID];
    //     require(
    //         s.soldProductAmount[_productID][tradeID] > 0,
    //         "This trade has been marked completed"
    //     );
    //     require(
    //         p.creator == _msgSender() ||
    //             _msgSender() == LibDiamond.contractOwner(),
    //         "Unauthorized to cancel trade."
    //     );
    //     uint amountToRelease = s.soldProductAmount[_productID][tradeID];
    //     s.soldProductAmount[_productID][tradeID] = 0;

    //     require(
    //         send(
    //             s.soldProductBuyer[_productID][tradeID],
    //             amountToRelease,
    //             0,
    //             false
    //         ),
    //         "Unable to transfer money!"
    //     );
    //     emit TradeCanceled(_productID, tradeID, block.timestamp);
    // }

    // function releaseProductFundToSeller(
    //     uint256 _productID,
    //     uint tradeID
    // ) external {
    //     Product memory p = products[_productID];
    //     require(
    //         s.soldProductAmount[_productID][tradeID] > 0,
    //         "This trade has been marked completed"
    //     );
    //     require(p.isdirect, "Invalid product.");
    //     require(
    //         s.soldProductBuyer[_productID][tradeID] == _msgSender() ||
    //             _msgSender() == LibDiamond.contractOwner(),
    //         "Unauthorized to release funds."
    //     );

    //     uint amountToRelease = s.soldProductAmount[_productID][tradeID];
    //     s.soldProductAmount[_productID][tradeID] = 0;
    //     require(
    //         send(p.creator, amountToRelease, 0, false),
    //         "Unable to transfer money!"
    //     );
    //     emit ReleaseProductFundToSeller(_productID, tradeID, block.timestamp);
    // }

    function send(
        address _recipient,
        uint _amount,
        uint qty,
        bool isBurn
    ) internal returns (bool) {
        GETADDRESSES getAddress = GETADDRESSES(address(this));
        (address egcAddr, address eusdAddr) = getAddress.getAddresses();
        IERC20PRODUCTINTERFACE __ierc20 = IERC20PRODUCTINTERFACE(eusdAddr);
        if (isBurn) {
            require(
                __ierc20.allowance(_msgSender(), address(this)) >=
                    _amount
                        .divideDecimal(uint256(Utils.DIVISOR_A))
                        .multiplyDecimal(qty),
                "Insufficient allowance for buyinng!"
            );
            //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
            __ierc20.burnFrom(
                _recipient,
                _amount.divideDecimal(uint256(Utils.DIVISOR_A)).multiplyDecimal(
                    qty
                )
            );
        } else {
            require(__ierc20.mint(_recipient, _amount), "Sending faild");
        }

        return true;
    }
}

//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
