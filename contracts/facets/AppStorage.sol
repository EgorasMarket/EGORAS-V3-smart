// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

struct AppStorage {
  mapping (address=>bool)  pythia;
  mapping(address => address[]) myReferrals;
  mapping(address => uint) staffId;
  

}