// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
import "./AppStorage.sol";

interface IERC20SAL {
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

contract SalaryFacet {
    AppStorage internal s;
    using SafeMath for uint256;
    using SafeDecimalMath for uint;
    struct Staffs {
        uint salary;
        address account;
        string name;
        uint nextPayDate;
    }
    Staffs[] staffs;
    event StaffEnrolled(
        uint salary,
        address account,
        string name,
        uint staffId,
        uint time
    );

    event SalaryPaid(uint salary, address account, uint nextPayDate, uint time);
    event StaffRemoved(address staff, uint time);

    function AddStaffs(
        string[] calldata _name,
        address[] calldata _account,
        uint[] calldata _salary
    ) external onlyOwner {
        require(_name.length == _account.length, "Invalid parameters");
        require(_salary.length == _account.length, "Invalid parameters");
        for (uint256 i; i < _name.length; i++) {
            Staffs memory staff = Staffs({
                salary: _salary[i],
                account: _account[i],
                name: _name[i],
                nextPayDate: block.timestamp.add(30 days)
            });
            staffs.push(staff);
            uint256 staffId = staffs.length - 1;
            s.staffId[_account[i]] = staffId;
            emit StaffEnrolled(
                _salary[i],
                _account[i],
                _name[i],
                staffId,
                block.timestamp
            );
        }
    }

    function PayStaffs() external onlyOwner {
        for (uint256 i = 0; i < staffs.length; i++) {
            Staffs storage staff = staffs[i];
            IERC20SAL eusd = IERC20SAL(s.eusdAddr);
            if (block.timestamp >= staff.nextPayDate) {
                require(
                    eusd.mint(staff.account, staff.salary),
                    "Fail to transfer fund"
                );
                staff.nextPayDate = block.timestamp.add(30 days);
                emit SalaryPaid(
                    staff.salary,
                    staff.account,
                    block.timestamp.add(30 days),
                    block.timestamp
                );
            }
        }
    }

    function removeStaffs(address[] calldata _staffs) external onlyOwner {
        for (uint256 index = 0; index < _staffs.length; index++) {
            delete staffs[s.staffId[_staffs[index]]];
            emit StaffRemoved(_staffs[index], block.timestamp);
        }
    }

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
}
