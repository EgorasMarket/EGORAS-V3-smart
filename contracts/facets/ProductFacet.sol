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
    event NFTMinted(uint256 productID, uint256 tokenID, uint256 time);
    event ReleaseProductFundToSeller(
        uint256 _productID,
        uint256 tradeID,
        uint256 time
    );
    modifier onlySystem() {
        require(
            _msgSender() == LibDiamond.contractOwner() ||
                s.pythia[_msgSender()] == true,
            "Access denied, Only system is allowed!"
        );
        _;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _productCounter;
    Counters.Counter private _soldProductCounter;

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

    function listProduct(
        string memory _title,
        uint256 _amount,
        uint256 _qty,
        bool _isdirect
    ) external {
        require(
            s.member[_msgSender()],
            "You're not a member, please subscribe to any membership plan and try again."
        );
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
            selling: _amount,
            creator: _msgSender(),
            tradable: false,
            qty: _qty,
            isdirect: _isdirect,
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

    function bid(uint256 _productID, uint256 _amount) external {
        Product storage p = products[_productID];
        require(!p.isdirect, "Invalid product type.");
        require(!p.tradable, "Bidding is over.");
        p.latestBid = _amount;
        p.isBidding = true;
        emit Bid(_productID, _amount, _msgSender(), block.timestamp);
    }

    function approveDirectProduct(uint256 _productID) external onlySystem {
        Product storage p = products[_productID];
        require(!p.isApprove, "Already approved.");
        require(p.isdirect, "Invalid product type.");
        p.isApprove = true;

        _mintNft(_productID, p.qty);

        emit ProductApproved(_productID, block.timestamp);
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
        require(!p.isdirect, "Invalid product type.");

        p.tradable = true;
        uint256 newProductSellingAmount = p.amount.multiplyDecimal(
            Utils.SALE_PERCENTAGE
        );
        p.selling = p.amount.add(newProductSellingAmount);
        IERC20PRODUCTINTERFACE __eusd = IERC20PRODUCTINTERFACE(s.eusdAddr);
        _mintNft(_productID, p.qty);
        require(
            __eusd.mint(
                p.creator,
                p
                    .amount
                    .divideDecimal(uint256(Utils.DIVISOR_A))
                    .multiplyDecimal(p.qty)
            ),
            "Fail to transfer fund"
        );

        emit Approved(
            _productID,
            _msgSender(),
            p.amount.add(newProductSellingAmount),
            block.timestamp
        );
    }

    function getSelling(
        uint256 _productID
    ) external view returns (uint256 _sellingAmount) {
        Product memory p = products[_productID];
        return (p.selling);
    }

    function isSelling(
        uint256 _productID
    ) external view returns (bool _isSelling) {
        Product memory p = products[_productID];
        return (p.tradable);
    }

    function buyProduct(uint256 _productID, uint qty) external {
        Product storage p = products[_productID];
        uint256 soldProductCounter = _soldProductCounter.current();
        require(p.qty >= qty, "Product is out of stock!");
        require(!p.isdirect, "Invalid product type.");
        require(p.tradable, "Product is not yet approved/sold");
        IERC20PRODUCTINTERFACE __iERC20 = IERC20PRODUCTINTERFACE(s.eusdAddr);

        require(
            __iERC20.allowance(_msgSender(), address(this)) >=
                p
                    .selling
                    .divideDecimal(uint256(Utils.DIVISOR_A))
                    .multiplyDecimal(qty),
            "Insufficient allowance for buyinng!"
        );
        //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
        __iERC20.burnFrom(
            _msgSender(),
            p.selling.divideDecimal(uint256(Utils.DIVISOR_A)).multiplyDecimal(
                qty
            )
        );
        s.soldProductAmount[_productID][soldProductCounter] = p
            .selling
            .divideDecimal(uint256(Utils.DIVISOR_A))
            .multiplyDecimal(qty);
        s.soldProductBuyer[_productID][soldProductCounter] = _msgSender();

        p.qty = p.qty.sub(qty);
        _soldProductCounter.increment();
        emit Sold(
            _productID,
            qty,
            soldProductCounter,
            _msgSender(),
            block.timestamp
        );
    }

    function buyDirectProduct(uint256 _productID, uint qty) external {
        Product storage p = products[_productID];
        uint256 soldProductCounter = _soldProductCounter.current();
        require(p.isdirect, "Invalid product type.");
        require(p.isApprove, "This product is not approved.");
        require(p.qty >= qty, "Product is out of stock!");
        IERC20PRODUCTINTERFACE __iERC20 = IERC20PRODUCTINTERFACE(s.eusdAddr);

        require(
            __iERC20.allowance(_msgSender(), address(this)) >=
                p
                    .amount
                    .divideDecimal(uint256(Utils.DIVISOR_A))
                    .multiplyDecimal(qty),
            "Insufficient allowance for buyinng!"
        );
        //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
        __iERC20.burnFrom(
            _msgSender(),
            p.amount.divideDecimal(uint256(Utils.DIVISOR_A)).multiplyDecimal(
                qty
            )
        );

        s.soldProductAmount[_productID][soldProductCounter] = p
            .selling
            .divideDecimal(uint256(Utils.DIVISOR_A))
            .multiplyDecimal(qty);
        s.soldProductBuyer[_productID][soldProductCounter] = _msgSender();
        p.qty = p.qty.sub(qty);
        _soldProductCounter.increment();
        emit Sold(
            _productID,
            qty,
            soldProductCounter,
            _msgSender(),
            block.timestamp
        );
    }

    function releaseProductFundToSeller(
        uint256 _productID,
        uint tradeID
    ) external {
        Product memory p = products[_productID];
        require(p.isdirect, "Invalid product.");
        require(
            s.soldProductBuyer[_productID][tradeID] == _msgSender() ||
                _msgSender() == LibDiamond.contractOwner(),
            "Unauthorized to release funds."
        );
        IERC20PRODUCTINTERFACE __ierc20 = IERC20PRODUCTINTERFACE(s.eusdAddr);
        require(
            __ierc20.mint(p.creator, s.soldProductAmount[_productID][tradeID]),
            "Sending faild"
        );

        emit ReleaseProductFundToSeller(_productID, tradeID, block.timestamp);
    }

    function setAddress(address _a) external onlySystem {
        s.eusdAddr = _a;
    }
}

//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
