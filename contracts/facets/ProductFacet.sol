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
}

contract ProductFacet is ERC721, ERC721URIStorage {
    AppStorage internal s;
    using SafeMath for uint256;
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
    event Sold(uint256 productID, uint qty, address buyer, uint256 time);
    event NFTMinted(uint256 productID, uint256 tokenID, uint256 time);
    modifier onlySystem() {
        require(
            _msgSender() == LibDiamond.contractOwner() ||
                s.pythia[_msgSender()] == true,
            "Access denied, Only system is allowed!"
        );
        _;
    }

    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;
    Counters.Counter private _productCounter;

    function setupNFT(
        string memory _nftName,
        string memory _nftSymbol
    ) external onlySystem {
        setConstructor(_nftName, _nftSymbol);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://egoras-v3-staging.egoras.com/product/nft/product/by/";
    }

    function safeMint(address to, string memory uri, uint _productID) internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit NFTMinted(_productID, tokenId, block.timestamp);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function listProduct(
        string memory _title,
        uint256 _amount,
        uint _qty,
        bool _isdirect
    ) external {
        // require(
        //     s.member[_msgSender()],
        //     "You're not a member, please subscribe to any membership plan and try again"
        // );
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
            isdirect: _isdirect
        });
        products.push(_product);

        if (_isdirect) {
            _mintNft(productID, _qty);
        }
        emit ProductCreated(
            _title,
            _amount,
            _msgSender(),
            false,
            productID,
            block.timestamp
        );
    }

    function _mintNft(uint _productID, uint _qty) internal {
        for (uint i = 0; i < _qty; i++) {
            safeMint(_msgSender(), _baseURI(), _productID);
        }
    }

    function productState(
        uint256 _productID
    )
        external
        view
        returns (bool isBidding, uint256 latestBid, address _creator)
    {
        Product memory p = products[_productID];
        return (p.isBidding, p.latestBid, p.creator);
    }

    function bid(uint256 _productID, uint256 _amount) external {
        Product storage p = products[_productID];
        require(!p.isdirect, "Invalid product type.");
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
        require(!p.isdirect, "Invalid product type.");
        IERC20 eusd = IERC20(s.eusdAddr);
        require(
            eusd.mint(p.creator, p.amount.multiplyDecimal(p.qty)),
            "Fail to transfer fund"
        );
        uint256 newProductSellingAmount = p.amount.multiplyDecimal(
            Utils.SALE_PERCENTAGE
        );
        p.selling = p.amount.add(newProductSellingAmount);
        _mintNft(_productID, p.qty);
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
        require(!p.isdirect, "Invalid product type.");
        require(p.tradable, "Product is not yet approved/sold");
        IERC20 iERC20 = IERC20(s.eusdAddr);
        require(
            iERC20.allowance(_msgSender(), address(this)) >=
                p.selling.multiplyDecimal(qty),
            "Insufficient allowance for buyinng!"
        );
        //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
        iERC20.burnFrom(_msgSender(), p.selling.multiplyDecimal(qty));
        p.tradable = false;
        emit Sold(_productID, qty, _msgSender(), block.timestamp);
    }

    function buyDirectProduct(uint256 _productID, uint qty) external {
        Product storage p = products[_productID];
        require(p.isdirect, "Invalid product type.");
        require(p.qty >= qty, "Product is out of stock!");
        IERC20 iERC20 = IERC20(s.eusdAddr);
        require(
            iERC20.allowance(_msgSender(), address(this)) >=
                p.amount.multiplyDecimal(qty),
            "Insufficient allowance for buyinng!"
        );
        //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
        iERC20.burnFrom(_msgSender(), p.amount.multiplyDecimal(qty));
        p.tradable = false;
        emit Sold(_productID, qty, _msgSender(), block.timestamp);
    }

    // function directListing(string memory _title, uint256 _amount) external {
    //     require(
    //         s.member[_msgSender()],
    //         "You're not a member, please subscribe to any membership plan and try again"
    //     );
    //     require(_amount > 0, "Product amount should be greater than zero");
    //     require(
    //         bytes(_title).length > 3,
    //         "Product title should more than three characters long"
    //     );

    //     Product memory _product = Product({
    //         title: _title,
    //         amount: _amount,
    //         isBidding: false,
    //         latestBid: 0,
    //         selling: _amount,
    //         creator: _msgSender(),
    //         tradable: true
    //     });
    //     products.push(_product);
    //     uint256 newProductID = products.length - 1;
    //     emit DirectProductCreated(
    //         _title,
    //         _amount,
    //         _msgSender(),
    //         true,
    //         newProductID,
    //         block.timestamp
    //     );
    // }
}
