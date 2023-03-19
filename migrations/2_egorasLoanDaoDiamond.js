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
      console.log(val.signature, val.name);
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

module.exports = function (deployer, network, accounts) { 
  deployer.deploy(StakingFacet);
deployer.deploy(MembershipFacet);
 deployer.deploy(PriceOracleFacet);
 deployer.deploy(ProductFacet);
 deployer.deploy(SalaryFacet);
 
 deployer.deploy(SwapFacet);
  deployer.deploy(DiamondCutFacet)
  deployer.deploy(DiamondLoupeFacet)

  deployer.deploy(OwnershipFacet).then(() => {
    const diamondCut = [
      [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      [PriceOracleFacet.address, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      [MembershipFacet.address, FacetCutAction.Add, getSelectors(MembershipFacet)],
      [ProductFacet.address, FacetCutAction.Add, getSelectors(ProductFacet)],
      [SalaryFacet.address, FacetCutAction.Add, getSelectors(SalaryFacet)],
      [StakingFacet.address, FacetCutAction.Add, getSelectors(StakingFacet)],
      [SwapFacet.address, FacetCutAction.Add, getSelectors(SwapFacet)],
      [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)],
    ]
    return deployer.deploy(EgorasV3, diamondCut, [accounts[0]])
 })
}
 