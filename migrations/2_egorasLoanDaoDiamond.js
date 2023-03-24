/* eslint-disable prefer-const */
/* global artifacts */
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const MembershipFacet = artifacts.require('MembershipFacet')
const PriceOracleFacet = artifacts.require('PriceOracleFacet')
const ProductFacet = artifacts.require('ProductFacet')
const SalaryFacet = artifacts.require('SalaryFacet')
const StakingFacet = artifacts.require('StakingFacet')
const SwapFacet = artifacts.require('SwapFacet')
const EgorasV3 = artifacts.require('EgorasV3')


const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}


//

function getSelectors (contract) {
  const selectors = contract.abi.reduce((acc, val) => {
    if (val.type === 'function') {
      acc.push(val.signature)
     // console.log(val.signature, val.name);
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

module.exports = function (deployer, network, accounts) { 
  //deployer.deploy(StakingFacet);
//return deployer.deploy(MembershipFacet);
//  deployer.deploy(PriceOracleFacet);
//  deployer.deploy(ProductFacet);
//  deployer.deploy(SalaryFacet);
 
 //deployer.deploy(SwapFacet);
 // deployer.deploy(DiamondCutFacet);
 // deployer.deploy(DiamondLoupeFacet);
  const diamondCut = [
      ["0x8aB0c7CE354dC9e83054AA6e5f51e5132D874FF3", 0, [ '0x1f931c1c' ]],
      ["0x911CFA89d5E6Fdc6a2dB0C9E822AFeb5A6d9c056", 0, ['0x7a0ed627','0xadfca15e','0x52ef6b2c','0xcdffacc6','0x01ffc9a7']],
      ["0x12D298fe0614218f7eb61B00Cee444aDb533F24E", 0, ['0x734bc659','0xfe2c6198','0x832427da','0xb55bfc6f','0x5c60896d','0x94a72f1c']],
      ["0x8c34Ed5F3d4e348B47a38194C172BE1D08270480", 0, ['0xd1c6be68', '0x6bd50cef','0x60375738', '0x6cb49d7e','0xe2d87a0a', '0xd4ff7a85','0x0038e09a', '0x5518b833','0x8a0d515c', '0xd5de0f67','0x464bf241','0x77c6137b','0x44df8e70', '0x3a0e3409','0x593b79fe']],
      ["0x8650612A06DfD9c3dA1acb3c402bD417ac2DeFA0", 0, ['0x89a1b523','0x013e11f5','0x598647f8','0x2b1fd58a','0x27d55495','0xb364acd6','0x20e124f7','0x8642269e']],
      ["0x47f63fD6171403178131bca9D455f868D7345335", 0, [ '0x0292e391', '0xdc407b61', '0x8e1e14dd']],
      ["0x61e6C30879D91C19785F8cC9072Ea4028c040b26", 0, [ '0x076f2129', '0xcad44b33', '0x2e2d3122', '0xd045bbee' ]],
      ["0x04092A3B0147C55B4602Af0d75909e94E5C16E78", 0, ['0x57ca2ad3','0x0f56add4','0x529828ad','0x66663156','0x64b56e38','0xfc2d82b1','0x3cb8d1a9','0xbe57ce41','0x35c3ba4b']],
      ["0xd474ef1F654f9493c0713021EfAA64242b442Fa7", 0, [ '0xf2fde38b', '0x8da5cb5b' ]],
    ]
  return deployer.deploy(EgorasV3, diamondCut, [accounts[0]]);
  
return deployer.deploy(OwnershipFacet);
  deployer.deploy(OwnershipFacet).then(() => {
    // const diamondCut = [
    //   [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
    //   [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
    //   [PriceOracleFacet.address, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
    //   [MembershipFacet.address, FacetCutAction.Add, getSelectors(MembershipFacet)],
    //   [ProductFacet.address, FacetCutAction.Add, getSelectors(ProductFacet)],
    //   [SalaryFacet.address, FacetCutAction.Add, getSelectors(SalaryFacet)],
    //   [StakingFacet.address, FacetCutAction.Add, getSelectors(StakingFacet)],
    //   [SwapFacet.address, FacetCutAction.Add, getSelectors(SwapFacet)],
    //   [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)],
    // ]
    // console.log("-----------------------DiamondCutFacet--------------------------");
    // console.log(getSelectors(DiamondCutFacet));
    // console.log("-----------------------DiamondCutFacet--------------------------");


    // console.log("-----------------------DiamondLoupeFacet--------------------------");
    // console.log(getSelectors(DiamondLoupeFacet));
    // console.log("-----------------------DiamondLoupeFacet--------------------------");

 
    // console.log("-----------------------PriceOracleFacet--------------------------");
    // console.log(getSelectors(PriceOracleFacet));
    // console.log("-----------------------PriceOracleFacet--------------------------");

    // console.log("-----------------------MembershipFacet--------------------------");
    // console.log(getSelectors(MembershipFacet));
    // console.log("-----------------------MembershipFacet--------------------------");

    // console.log("-----------------------ProductFacet--------------------------");
    // console.log(getSelectors(ProductFacet));
    // console.log("-----------------------ProductFacet--------------------------");

    // console.log("-----------------------SalaryFacet--------------------------");
    // console.log(getSelectors(SalaryFacet));
    // console.log("-----------------------SalaryFacet--------------------------");

    // console.log("-----------------------StakingFacet--------------------------");
    // console.log(getSelectors(StakingFacet));
    // console.log("-----------------------StakingFacet--------------------------");

    // console.log("-----------------------SwapFacet--------------------------");
    // console.log(getSelectors(SwapFacet));
    // console.log("-----------------------SwapFacet--------------------------");


    // console.log("-----------------------OwnershipFacet--------------------------");
    // console.log(getSelectors(OwnershipFacet));
    // console.log("-----------------------OwnershipFacet--------------------------");
    

    return deployer.deploy(EgorasV3, diamondCut, [accounts[0]])
 })
}
 