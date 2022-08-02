/* eslint-disable prefer-const */
/* global artifacts */

const EgorasLoanDaoV2 = artifacts.require('EgorasLoanDaoV2')
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const EgorasLoanV2Facet = artifacts.require('EgorasLoanV2Facet')
const EgorasLoanV2ReferralFacet = artifacts.require('EgorasLoanV2ReferralFacet')
const EgorasPriceOracleFacet = artifacts.require('EgorasPriceOracleFacet')
const ERC721 = artifacts.require('ERC721')

const EgorasSwapFacet = artifacts.require('EgorasSwapFacet')

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
      console.log(val.signature);
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

module.exports = function (deployer, network, accounts) {
  //getSelectors(EgorasLoanV2ReferralFacet)
 
 return deployer.deploy(EgorasLoanV2Facet);
// deployer.deploy(EgorasPriceOracleFacet);
//  deployer.deploy(EgorasSwapFacet);
//   deployer.deploy(DiamondCutFacet)
//   deployer.deploy(DiamondLoupeFacet)
//   deployer.deploy(OwnershipFacet).then(() => {
//     const diamondCut = [
//       [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
//       [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
//       [EgorasPriceOracleFacet.address, FacetCutAction.Add, getSelectors(EgorasPriceOracleFacet)],
//       [EgorasLoanV2Facet.address, FacetCutAction.Add, getSelectors(EgorasLoanV2Facet)],
//       [EgorasSwapFacet.address, FacetCutAction.Add, getSelectors(EgorasSwapFacet)],
//       [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)],
//     ]
//     return deployer.deploy(EgorasLoanDaoV2, diamondCut, [accounts[0]])
 // })
}
 