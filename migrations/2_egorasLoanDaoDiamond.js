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
const PancakeSwapFacet = artifacts.require('PancakeSwapFacet')
//const ProductAdapter = artifacts.require('ProductAdapter')


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
      
      // console.log("Start------"+contract.contractName+"--------Start")
      // console.log([contract.contractName, 0, acc])
      //  console.log("END------"+contract.contractName+"--------END")
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

module.exports = function (deployer, network, accounts) { 
//   return deployer.deploy(PancakeSwapFacet).then(() =>{
//  console.log("-----------------------PancakeSwapFacet--------------------------");
//   console.log(getSelectors(PancakeSwapFacet));
//   console.log("-----------------------PancakeSwapFacet--------------------------");
//   })

//  return deployer.deploy(ProductFacet).then(()=> {
//  return getSelectors(ProductFacet)
//  });

const deploy = [
  [ '0xC602De3Ff5Ba266EeD4B13934D1A3BDd4DE88679', 0, [ '0x1f931c1c' ] ],
  [
    '0xFDC857E32a1dFb09832993594bF9e47544246C70',
    0,
    [
      '0x7a0ed627',
      '0xadfca15e',
      '0x52ef6b2c',
      '0xcdffacc6',
      '0xaf8a2625'
    ]
  ],
  [
    '0xf721257dAAE194a46FF92c892995e92DE1E571d5',
    0,
    [
      '0x734bc659',
      '0xfe2c6198',
      '0x832427da',
      '0xb55bfc6f',
      '0x5c60896d',
      '0x94a72f1c'
    ]
  ],
  [
    '0x289FAE72B0E4a5747a9B50CAc20e357c49e25206',
    0,
    [
      '0xd1c6be68', '0xa39fac12',
      '0x6bd50cef', '0x2510bed1',
      '0x9eda380a', '0x3910fda5',
      '0x2b8a2434', '0x1fa0fbec',
      '0xf320bed4', '0x6be44073',
      '0x1a915049', '0xdafac561',
      '0xe4721b1a', '0x44df8e70',
      '0xa90f8e9a', '0x3a0e3409',
      '0xfab96348', '0x593b79fe',
      '0x5d672a62', '0xfc53c821',
      '0xab3545e5', '0xa9006616'
    ]
  ],
  [
    '0x9E2cf66EdC1b56A4254b5Ff5BA2F626E1d5F2ae6',
    0,
    [
      '0x095ea7b3', '0x70a08231',
      '0x081812fc', '0xe985e9c5',
      '0x6352211e', '0x42842e0e',
      '0xb88d4fde', '0xa22cb465',
      '0x23b872dd', '0x01ffc9a7',
      '0x18160ddd', '0x06fdde03',
      '0x95d89b41', '0xc87b56dd',
      '0x3eca6995', '0x013e11f5',
      '0x598647f8', '0x9033e995',
      '0x2b1fd58a', '0x27d55495',
      '0xdc78d93b', '0xdf88480f',
      '0x64339dbf', '0x75681d0e'
    ]
  ],
  [ '0xc740fd7aaF017c594Ddf58eCCC98eE0312EB7DcB', 0, [ '0x0292e391', '0xdc407b61', '0x8e1e14dd' ] ],
  [
    '0xC9f86D4b806955E8c96B60229615824f5b5E4f73',
    0,
    [
      '0x2def6620', '0x076f2129',
      '0xcad44b33', '0x2e2d3122',
      '0x0dedd016', '0x8c09a2f9',
      '0xd045bbee', '0xd55e2961',
      '0x3ccd1bb4', '0x57c71c91',
      '0x04d5bcfd'
    ]
  ],
  [
    '0xFc58F1D90e4B96622f82302Cf0bDB7f8D7f59B20',
    0,
    [
      '0xcf1d14dc', '0x9c48a3c3',
      '0x9f593c33', '0x82382e88',
      '0x04c26712', '0xe51f25c0',
      '0x4966c27e', '0x9f7414e9',
      '0xd27fe916', '0xa8312b1d',
      '0x9e269b68'
    ]
  ],
  [ '0x4bd8818B8D0F51b764d67edca8ba81a47cF0Fc99', 0, [ '0xf2fde38b', '0x8da5cb5b' ] ]
];



 return deployer.deploy(EgorasV3, deploy, [accounts[0]])

 

 deployer.deploy(StakingFacet)
 deployer.deploy(MembershipFacet);
 deployer.deploy(PriceOracleFacet);
 deployer.deploy(ProductFacet);
 deployer.deploy(SalaryFacet);
 deployer.deploy(PancakeSwapFacet);
 deployer.deploy(DiamondCutFacet);
 deployer.deploy(DiamondLoupeFacet);

  deployer.deploy(OwnershipFacet).then(() => {
    const diamondCut = [
      [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      [PriceOracleFacet.address, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      [MembershipFacet.address, FacetCutAction.Add, getSelectors(MembershipFacet)],
      [ProductFacet.address, FacetCutAction.Add, getSelectors(ProductFacet)],
      [SalaryFacet.address, FacetCutAction.Add, getSelectors(SalaryFacet)],
      [StakingFacet.address, FacetCutAction.Add, getSelectors(StakingFacet)],
      [PancakeSwapFacet.address, FacetCutAction.Add, getSelectors(PancakeSwapFacet)],
      [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)],
    ]

       const diamondCut2 = [
      [DiamondCutFacet.contractName, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      [DiamondLoupeFacet.contractName, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      [PriceOracleFacet.contractName, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      [MembershipFacet.contractName, FacetCutAction.Add, getSelectors(MembershipFacet)],
      [ProductFacet.contractName, FacetCutAction.Add, getSelectors(ProductFacet)],
      [SalaryFacet.contractName, FacetCutAction.Add, getSelectors(SalaryFacet)],
      [StakingFacet.contractName, FacetCutAction.Add, getSelectors(StakingFacet)],
      [PancakeSwapFacet.contractName, FacetCutAction.Add, getSelectors(PancakeSwapFacet)],
      [OwnershipFacet.contractName, FacetCutAction.Add, getSelectors(OwnershipFacet)],
    ]

    console.log(diamondCut2);
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
 