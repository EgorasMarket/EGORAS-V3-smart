// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
import "./AppStorage.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/SafeDecimalMath.sol";
import "../libraries/SafeMath.sol";
contract ReferralFacet {

AppStorage internal s;

modifier onlyRPythia{
        require(s.pythia[msg.sender], "Access denied. Only Pythia is allowed!");
        _;
    }



}