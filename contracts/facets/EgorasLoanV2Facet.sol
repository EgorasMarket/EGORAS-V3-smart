// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function mint(address account, uint256 amount) external  returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
}

interface NFT {
function ownerOf(uint256 tokenId) external view returns (address);
function mint(address to, uint tokenID) external returns(bool);
function burn(uint tokenID) external returns(bool);
}

interface PRICEORACLE {
    /// @notice Gets price of a ticker ie ETH-EUSD.
    /// @return current price of a ticker
    function price(string memory _ticker) external view returns (uint);
}

contract EgorasLoanV2Facet{
      enum FacetAction {
        Loan,
        Dividend,
        Burned
    }

   using SafeDecimalMath for uint;
      struct Lenders{
            uint id;
            uint loadID;
            address user;
            uint amount;
            uint date;
            uint earningStartDate;
            uint interestCollected;
            address branch;
            bool collected;
        }
    Lenders[] private lenders;
   
    mapping(address => mapping(uint => uint)) findLenderByAddress;

    mapping(address => mapping(uint => uint)) userTotalLoanDividendCollected;
    mapping(address => uint) userTotalAllLoanDividendCollected;

    mapping(uint => uint) totalLoanDividendCollected;
    mapping(uint => uint) stats;
    mapping(uint => uint) lends;
    uint private totalAllLoanDividendCollected;

    mapping(address => mapping(uint => bool)) isALender;
    uint private INTEREST_DIVISOR;
    uint private DIVIDEND_DIVISOR;
    uint private INTEREST;
    uint private DAYINMILL;
    address private egorasEGC;
    address private eNFTAddress;
    address private egorasENGN;
    address private oracle;
    string private ticker;

    event NFTBurned(uint _time, uint _loanID, address _branch);  
    event DividendBurned(uint _time, uint _loanID, address _branch);
    event NewLender(address _user, uint _id, uint _amount, address _branch, uint _time, uint _loanID);
    event Collected(uint _loanID, uint _lenderID, uint _amount, uint _time, address _branch);
    event BranchAdded(address _branch, string name, uint _time);
    event BranchSuspended(address _branch, uint _time);
     struct Loan{
        uint id;
        string title;
        uint amount;
        uint length;
        address branch;
        string loanMetaData;
        bool repaid;
    }
 modifier onlyOwner{
        require(_msgSender() == LibDiamond.contractOwner(), "Access denied, Only owner is allowed!");
        _;
    }
  Loan[] loans;
  using SafeMath for uint256;
  mapping(address => bool)  branchAddress;
  event Repay(uint _amount, uint _accumulated, uint _time, uint _loanID, address _branch);
  event LoanCreated(
        uint newLoanID, string _title,  uint _amount,  uint _length, 
       address _branch,
       string _metadata);
  event TakeDividend(uint _loanID, uint _dividend, address _user, uint _next, uint _lendID, uint _time, address _branch);
  event Burned(address _burnedBy, uint burnAmount, uint _time);  
 function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }


   function addBranch(address _branch, string memory _branchName) external onlyOwner returns(bool){
        branchAddress[_branch] = true;
        emit BranchAdded(_branch, _branchName, block.timestamp);
        return true;
    }
     function addNFTAddress(address _eNFTAddress) external onlyOwner returns(bool){
        eNFTAddress = _eNFTAddress;
        return true;
    }

   

   function suspendBranch(address _branch) external onlyOwner returns(bool) {
       branchAddress[_branch] = false;
       emit BranchSuspended(_branch, block.timestamp);
       return true;
   }

    /*** Restrict access to Branch role*/    
      modifier onlyBranch() {        
        require(branchAddress[msg.sender] == true, "Address is not allowed to upload a loan!");       
        _;}

  function getLender(address _user, uint _loanID) external view returns(Lenders memory _lender){
    Lenders memory lender = lenders[findLenderByAddress[_user][_loanID]];
    return(lender);
    }

function getInvestorsDividend(address _user, uint _loanID) external view returns (uint){
Lenders memory l = lenders[findLenderByAddress[_user][_loanID]];
uint _share = uint(uint(l.amount).divideDecimal(uint(DIVIDEND_DIVISOR)).multiplyDecimal(uint(INTEREST)));
return _share;
} 


function lendUS(
        address _branch,
        uint _amount,
        uint loanID
    ) external {
        require(_amount > 0, "Amount must be greater than zero!");
        require(!isALender[_msgSender()][loanID], "Already a lender, you can only top up!");
        require(_amount <= IERC20(egorasENGN).allowance(_msgSender(), address(this)), "Allowance not high enough");
        require(IERC20(egorasENGN).transferFrom(_msgSender(), address(this), _amount), "Unable to make withdrawal from your account!");
        Loan memory l = loans[loanID];
        require(l.amount > 0, "Invalid loan!");
        require(!l.repaid, "This loan is closed!");
        require(l.amount >= lends[loanID].add(_amount), "Please reduce lend amount!");
        Lenders memory _lenders  = Lenders({
             id: lenders.length,
             loadID: loanID,
             user: _msgSender(),
             amount: _amount,
             date: block.timestamp,
             earningStartDate: block.timestamp + 30 days,
             interestCollected: 0,
             branch: _branch,
             collected: false
             
        }); 
         lenders.push(_lenders);
         uint id = lenders.length - 1;
         findLenderByAddress[_msgSender()][loanID] = id;
         lends[loanID] = lends[loanID].add(_amount);
         isALender[_msgSender()][loanID] = !isALender[_msgSender()][loanID];
         emit NewLender(_msgSender(), id, _amount,_branch, block.timestamp, loanID);
    }

  

 function applyForLoan(
        string memory _title,
        uint _amount
        // uint _length,
        // string memory _loanMetaData
        ) external onlyBranch {
        require(_amount > 0, "Loan amount should be greater than zero");
        // require(_length > 0, "Loan duration should be greater than zero");
        require(bytes(_title).length > 3, "Loan title should more than three characters long");
         Loan memory _loan = Loan({
         id: loans.length,
         title: _title,
         amount: _amount,
         length: 0,
         branch: _msgSender(),
         loanMetaData: "",
         repaid: false
        });
        NFT ENFT = NFT(eNFTAddress);
        loans.push(_loan);
        uint newLoanID = loans.length - 1;
        require(ENFT.mint(_msgSender(), newLoanID), "Unable to mint token");
        emit LoanCreated(newLoanID, _title, _amount, 0, _msgSender(), "");
        }

function userStats(uint _loanID, address _user) external view returns(uint _dividend, uint _allDividend){
    return(
        userTotalLoanDividendCollected[_user][_loanID],
        userTotalAllLoanDividendCollected[_user]
    );
}
function takeDividend(uint _loanID) external{
    Lenders storage l = lenders[findLenderByAddress[_msgSender()][_loanID]];
    Loan memory loan = loans[_loanID];
    require(!loan.repaid, "This loan has been fully paid.");
    require(block.timestamp >= l.earningStartDate, "dividend is not matured.");
    uint dividend = this.getInvestorsDividend(_msgSender(), _loanID);
    uint daysDiff = (block.timestamp - l.earningStartDate) / 60 / 60 / 24;
    uint next = l.earningStartDate.add(30 days);
    l.earningStartDate = next.sub(DAYINMILL.multiplyDecimalRound(daysDiff));
    IERC20 TOKEN = IERC20(egorasENGN);
    require(TOKEN.mint(_msgSender(), dividend), "Fail to transfer fund");
    userTotalLoanDividendCollected[_msgSender()][_loanID] = userTotalLoanDividendCollected[_msgSender()][_loanID].add(dividend);
    userTotalAllLoanDividendCollected[_msgSender()] = userTotalAllLoanDividendCollected[_msgSender()].add(dividend);
    totalLoanDividendCollected[_loanID] = totalLoanDividendCollected[_loanID].add(dividend);
    totalAllLoanDividendCollected = totalAllLoanDividendCollected.add(dividend);
    emit TakeDividend(_loanID, dividend,_msgSender(),l.earningStartDate, findLenderByAddress[_msgSender()][_loanID],block.timestamp, loan.branch);
}
function takeBackLoan(uint _loanID) external{
 Loan memory loan = loans[_loanID];
 require(loan.repaid, "This you loan is not fully repaid");
 Lenders storage l = lenders[findLenderByAddress[_msgSender()][_loanID]];
 require(!l.collected, "You have collected back your fund.");
 IERC20 TOKEN = IERC20(egorasENGN);
 require(TOKEN.transfer(_msgSender(), l.amount), "Fail to transfer fund");
 l.collected = true;
 emit Collected(_loanID, findLenderByAddress[_msgSender()][_loanID], l.amount, block.timestamp, loan.branch);
}


function burnAccumulatedDividend() external{
   IERC20 iERC20i = IERC20(egorasEGC);
   uint burn =  stats[uint(FacetAction.Dividend)];
   iERC20i.burn(burn);
   stats[uint(FacetAction.Burned)] =  stats[uint(FacetAction.Burned)].add(burn);
   emit Burned(_msgSender(), burn, block.timestamp);  
}

// function topupLend(uint _loanID, uint _amount) external{
//         Loan storage l = loans[_loanID];
//         require(_amount > 0, "Amount must be greater than zero!");
//         require(isALender[_msgSender()][_loanID], "Not a lender, you cannot top up!");
//         require(_amount <= IERC20(egorasENGN).allowance(_msgSender(), address(this)), "Allowance not high enough");
//         require(IERC20(egorasENGN).transferFrom(_msgSender(), address(this), _amount), "Unable to make withdrawal from your account!");
//         require(l.amount > 0, "Invalid loan!");
//         require(!l.repaid, "This loan is closed!");
//         Lenders storage _lenders  = lenders[findLenderByAddress[_msgSender()][_loanID]];
//        _lenders.amount = _lenders.amount.add(_amount);
//        _lenders.earningStartDate = block.timestamp.add(30 days);
//         lends[_loanID] = lends[_loanID].add(_amount);
//         emit NewLender(_msgSender(), findLenderByAddress[_msgSender()][_loanID], _amount,l.branch, block.timestamp, _loanID); 
// }

   function _getPri() internal view returns (uint) {
        PRICEORACLE p = PRICEORACLE(address(oracle));
        return p.price(ticker);
    }
    function getPri() external view returns (uint) {
        PRICEORACLE p = PRICEORACLE(address(oracle));
        return p.price(ticker);
    }
// function repayDividendLoan(uint _loanID) external{
//    Loan memory loan = loans[_loanID];
//    require(loan.branch == _msgSender(), "Unauthorized.");
//     require(loan.repaid, "Repay this loan first.");
//    uint price = _getPri();
//    uint accumulated = totalLoanDividendCollected[_loanID].divideDecimal(price);
//    IERC20 iERC20i = IERC20(egorasEGC);
//    require(iERC20i.transferFrom(_msgSender(), address(this),  accumulated), "Unable to withdraw dividend from your account!");
//    stats[uint(FacetAction.Dividend)] =  stats[uint(FacetAction.Dividend)].add(accumulated);
//    emit Repay(loan.amount, accumulated, block.timestamp, _loanID, loan.branch);  
// }


    // function burnNFT(uint _loanID) external{
    // Loan memory loan = loans[_loanID];
    // require(loan.branch == _msgSender(), "Unauthorized.");
    // require(loan.repaid, "Repay this loan first.");
    // NFT eNFT = NFT(eNFTAddress);
    // eNFT.burn(_loanID); 
    // }
// function repayOnlyLoan(uint _loanID) external{
//    Loan storage loan = loans[_loanID];
//    require(loan.branch == _msgSender(), "Unauthorized.");
//    IERC20 iERC20 = IERC20(egorasENGN);
//    require(iERC20.transferFrom(_msgSender(), address(this),  loan.amount), "Unable to make withdrawal from your account!");
//    stats[uint(FacetAction.Loan)] =  stats[uint(FacetAction.Loan)].add(loan.amount);
//    loan.repaid = true;
//    emit Repay(loan.amount, 0, block.timestamp, _loanID, loan.branch);  
// }






function getTotalLended(uint _loanID) external view returns(uint loan){
    return(lends[_loanID]);
}

function system() external view returns(uint _dividend, uint _repaid, uint _burned, uint _total){
    return(stats[uint(FacetAction.Dividend)], stats[uint(FacetAction.Loan)],  stats[uint(FacetAction.Burned)], totalAllLoanDividendCollected);
}



 function initSystem(
    uint _DIVIDEND_DIVISOR, 
    uint _INTEREST_DIVISOR, 
    uint _INTEREST,
    uint _DAYINMILL,
    address  _egorasEGC,
  address  _eNFTAddress,
  address  _egorasENGN,
  address _oracle,
 string memory  _ticker
    )external onlyOwner{
    INTEREST_DIVISOR = _INTEREST_DIVISOR;
    DIVIDEND_DIVISOR =  _DIVIDEND_DIVISOR;
    INTEREST = _INTEREST;
    DAYINMILL = _DAYINMILL;
    egorasEGC = _egorasEGC;
    eNFTAddress =  _eNFTAddress;
    egorasENGN = _egorasENGN;
    oracle = _oracle;
    ticker = _ticker;
 }

function getSystemVariables() onlyOwner external view returns(uint, uint, uint, uint, address, address,address, address, string memory ){
 return(INTEREST_DIVISOR,DIVIDEND_DIVISOR,INTEREST,DAYINMILL,egorasEGC,eNFTAddress,egorasENGN, oracle,ticker);
}
 function resetime(uint _loanID, address user, uint to ) external onlyOwner{
 Lenders storage l = lenders[findLenderByAddress[user][_loanID]];
 l.earningStartDate = to;
 }
function internalTopup(uint _loanID, uint _amount, address _user) external{
       require(_msgSender() == address(this), "You're not authorized!");
        Loan storage l = loans[_loanID];
        require(_amount > 0, "Amount must be greater than zero!");
        require(isALender[_user][_loanID], "Not a lender, you cannot top up!");
          require(l.amount > 0, "Invalid loan!");
        require(!l.repaid, "This loan is closed!");
        Lenders storage _lenders  = lenders[findLenderByAddress[_user][_loanID]];
       _lenders.amount = _lenders.amount.add(_amount);
       _lenders.earningStartDate = block.timestamp.add(30 days);
        lends[_loanID] = lends[_loanID].add(_amount);
        emit NewLender(_user, findLenderByAddress[_user][_loanID], _amount,l.branch, block.timestamp, _loanID); 
}
  function internalLending(
        address _branch,
        address _user,
        uint _amount,
        uint loanID
    ) external {
        require(_amount > 0, "Amount must be greater than zero!");
        require(!isALender[_user][loanID], "Already a lender, you can only top up!");
        require(_msgSender() == address(this), "You're not authorized!");
        Loan memory l = loans[loanID];
        require(l.amount > 0, "Invalid loan!");
        require(!l.repaid, "This loan is closed!");
        require(l.amount >= lends[loanID].add(_amount), "Please reduce lend amount!");
        Lenders memory _lenders  = Lenders({
             id: lenders.length,
             loadID: loanID,
             user: _user,
             amount: _amount,
             date: block.timestamp,
             earningStartDate: block.timestamp + 30 days,
             interestCollected: 0,
             branch: _branch,
             collected: false
             
        }); 
         lenders.push(_lenders);
         uint id = lenders.length - 1;
         findLenderByAddress[_user][loanID] = id;
         lends[loanID] = lends[loanID].add(_amount);
         isALender[_user][loanID] = !isALender[_user][loanID];
         emit NewLender(_user, id, _amount,_branch, block.timestamp, loanID);
    }

 // End of referral
 receive() external payable {}
 // Fallback function is called when msg.data is not empty
 fallback() external payable {}


}