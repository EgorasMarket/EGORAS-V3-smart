// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/Utils.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20 {
    function totalSupply() external view  returns (uint256);
    function balanceOf(address account) external view  returns (uint256);
    function transfer(address recipient, uint256 amount) external  returns (bool);
    function allowance(address owner, address spender) external  view returns (uint256);
    function approve(address spender, uint256 amount) external  returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)  external  returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external;
}

contract ProductFacet{
AppStorage internal s;
 using SafeMath for uint256;
 using SafeDecimalMath for uint;
 struct Product{
        string title;
        uint amount;
        uint selling;
        address creator;
        bool tradable;
    }
 Product[] products;

 event ProductCreated(string _title, uint _amount, address _creator, bool _tradable, uint _productID, uint _time);
 event Approved(uint productID, address approvedBy, uint nowSelling, uint time);
 event Sold(uint productID, address buyer, uint time);
modifier onlySystem{
        require(_msgSender() == LibDiamond.contractOwner() || s.pythia[_msgSender()] == true, "Access denied, Only system is allowed!");
        _;
    }  

 function _msgSender() internal view virtual returns (address) {
        return msg.sender;
}
     function listProduct(
        string memory _title,
        uint _amount
        ) external {
        require(s.member[_msgSender()], "You're not a member, please subscribe to any membership plan and try again");
        require(_amount > 0, "Product amount should be greater than zero");
        require(bytes(_title).length > 3, "Product title should more than three characters long");
         Product memory _product = Product({
         title: _title,
         amount: _amount,
         selling: _amount,
         creator: _msgSender(),
         tradable: false
        });
        products.push(_product);
        uint newProductID = products.length - 1;
        emit ProductCreated(_title, _amount, _msgSender(), false, newProductID, block.timestamp);
        }


    function approveProduct(uint _productID) external onlySystem{
        Product storage p = products[_productID];
        require(!p.tradable, "Product is already approved");
         IERC20 eusd = IERC20(s.eusdAddr);
        require(eusd.mint(p.creator, p.amount), "Fail to transfer fund");
        uint newProductSellingAmount = p.amount.multiplyDecimal(Utils.SALE_PERCENTAGE);
        p.selling = p.amount.add(newProductSellingAmount);
        emit Approved(_productID, _msgSender(), p.amount.add(newProductSellingAmount), block.timestamp);

    }

    function getSelling(uint _productID) external view returns(uint _sellingAmount){
          Product memory p = products[_productID];
          return(p.selling);
    }

    function isSelling(uint _productID) external view returns (bool _isSelling){
          Product memory p = products[_productID];
          return(p.tradable);
    }

    function buyProduct(uint _productID) external{
        Product storage p = products[_productID];
        require(p.tradable, "Product is not yet approved/sold");
        IERC20 iERC20 = IERC20(s.eusdAddr);
        require(iERC20.allowance(_msgSender(), address(this)) >= p.selling, "Insufficient allowance for buyinng!");
        //require(iERC20.burnFrom(_msgSender(), p.selling), "Unable to burn.");
        iERC20.burnFrom(_msgSender(), p.selling);
        p.tradable = false;
        emit Sold(_productID,_msgSender(), block.timestamp);
    }




}