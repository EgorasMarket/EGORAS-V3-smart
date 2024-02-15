/* eslint-disable prefer-const */
/* global artifacts */
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const MembershipFacet = artifacts.require('MembershipFacet')
const PriceOracleFacet = artifacts.require('PriceOracleFacet')
const ProductFacet = artifacts.require('ProductFacet')
const SalaryFacet = artifacts.require('SalaryFacet')
const SwapFacet = artifacts.require('SwapFacet')
const EgorasV3 = artifacts.require('EgorasV3')
const PancakeSwapFacet = artifacts.require('PancakeSwapFacet')
const MartGPTToken = artifacts.require('MartGPTToken')
const RewardFaucet = artifacts.require('RewardFaucet')
const DealersFacet = artifacts.require('DealersFacet')
const StakingFacet = artifacts.require('StakingFacet')
const StakingFacetStable = artifacts.require('StakingFacetStable')
const ConvertFacet = artifacts.require('ConvertFacet')
const DrawFundsFacet = artifacts.require('DrawFundsFacet')
const StakingFacetNew = artifacts.require('StakingFacetNew')
const ExFacet = artifacts.require('ExFacet')


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
  
  //return  deployer.deploy(PriceOracleFacet);
  //return deployer.deploy(MartGPTToken, "MartGPT Token","MA","0xb9bfBE13137A78ED3392866C479378a4f7595ef6","0xD195dCC364Beeedd3117e331a17e3A6863D1Aa43", "100000000000000000000000000000","100000000000000000000")
//return deployer.deploy(RewardFaucet);
  
  // return deployer.deploy(StakingFacet).then(() =>{
  //   const diamondCut2 = [
  //   [StakingFacet.contractName, FacetCutAction.Add, getSelectors(StakingFacet)]
  //   ];
  //   console.log("Start------RewardFaucet--------Start");
  //   console.log(diamondCut2);
  //   console.log("END-----RewardFaucet--------END");
  // })

//  return deployer.deploy(PancakeSwapFacet).then(()=> {
//   console.log("Start------ProductFacet--------Start")
//        console.log(["contract.contractName", 0, getSelectors(PancakeSwapFacet)])
//         console.log("END-----ProductFacet--------END")
//  });

// const deploy = [
//   [ '0x27d0fd6a1ff41db21ba24c66a90abc2e34053e0e', 0, [ '0x1f931c1c' ] ],
//   [
//     '0xd691b24b8d80602715a2124b9e98bcbb3e45a788',
//     0,
//     [
//       '0x7a0ed627',
//       '0xadfca15e',
//       '0x52ef6b2c',
//       '0xcdffacc6',
//       '0xaf8a2625'
//     ]
//   ],
//   [
//     '0x3b83ae5dd00717c9e3c58457789455ec5207e757',
//     0,
//     [
//       '0x734bc659',
//       '0x658bdb2e',
//       '0xfe2c6198',
//       '0x832427da',
//       '0xb55bfc6f',
//       '0x5c60896d',
//       '0x94a72f1c'
//     ]
//   ],
//   [
//     '0xcff34847a99a210e58e713a5a1f7ba78c6fd317b',
//     0,
//     [
//       '0xd1c6be68', '0xa39fac12',
//       '0x6bd50cef', '0x2510bed1',
//       '0x9eda380a', '0x3910fda5',
//       '0x2b8a2434', '0x1fa0fbec',
//       '0xf320bed4', '0x6be44073',
//       '0x1a915049', '0xdafac561',
//       '0xe4721b1a', '0x44df8e70',
//       '0x1f2781a6', '0x3c9f861d',
//       '0xa90f8e9a', '0x3a0e3409',
//       '0xfab96348', '0x593b79fe',
//       '0x5d672a62', '0xfc53c821',
//       '0xab3545e5'
//     ]
//   ],
//   [
//     '0xd9e1c00df4bcdda9faf08f0dee892c9295f0eb33',
//     0,
//     [
//       '0x095ea7b3', '0x70a08231',
//       '0x081812fc', '0xe985e9c5',
//       '0x6352211e', '0x42842e0e',
//       '0xb88d4fde', '0xa22cb465',
//       '0x23b872dd', '0x01ffc9a7',
//       '0x18160ddd', '0x06fdde03',
//       '0x95d89b41', '0xc87b56dd',
//       '0x3eca6995', '0x013e11f5',
//       '0x598647f8', '0x9033e995',
//       '0x2b1fd58a', '0x5c0fe63f',
//       '0xd4781dbf', '0x27d55495',
//       '0xdc78d93b', '0xdf88480f',
//       '0x64339dbf', '0x75681d0e'
//     ]
//   ],
//   [ '0x77bfd212c4b9d555700ea9b5d523f2a03ffc85a9', 0, [ '0x0292e391', '0xdc407b61', '0x8e1e14dd' ] ],
//   [
//     '0xc72429606c32fe8e60386447244deea865a1ae94',
//     0,
//     [
//       '0x2def6620', '0x076f2129',
//       '0xcad44b33', '0x2e2d3122',
//       '0x0dedd016', '0x8c09a2f9',
//       '0xd045bbee', '0xd55e2961',
//       '0x3ccd1bb4', '0x57c71c91',
//       '0x04d5bcfd'
//     ]
//   ],
//   [
//     '0x91925933151f5856e6f6cc24ce2b97c0340f445b',
//     0,
//     [
//       '0xcf1d14dc', '0x9c48a3c3',
//       '0x9f593c33', '0x82382e88',
//       '0x04c26712', '0xe51f25c0',
//       '0x4966c27e', '0x9f7414e9',
//       '0xd27fe916', '0xa8312b1d',
//       '0x9e269b68'
//     ]
//   ],
//   [ '0xb9aeb0575381482d35252c1d084f990fcf3cbe0a', 0, [ '0xf2fde38b', '0x8da5cb5b' ] ]
// ];

// const deploy2 = [['0x27d0fd6a1ff41db21ba24c66a90abc2e34053e0e', 0, ['0x1f931c1c']],['0xd691b24b8d80602715a2124b9e98bcbb3e45a788',0,['0x7a0ed627','0xadfca15e','0x52ef6b2c','0xcdffacc6','0xaf8a2625']],['0x8fff41232d586c160e760627b93a5ad9b92b0da0',0,['0x267561c8','0xfc3a49e0','0x94a72f1c']],['0xaadb2179b2ccba1129b782bb80908e2a1f107a33',0,['0xa61d6257','0x6b667b9b','0xf9f11391','0x901afb30','0x1355a306','0x89499f8d','0x235eb9f5','0x468c25a8','0xad830443']],['0x9fd3dedd790672ba64d78c4cc4ac4b733cbc4f90',0,['0x095ea7b3','0x70a08231','0x081812fc','0xe985e9c5','0x6352211e','0x42842e0e',
// '0xb88d4fde','0xa22cb465','0x23b872dd','0x01ffc9a7','0x18160ddd','0x06fdde03','0x95d89b41','0xc87b56dd','0x67a86045','0x1607627e','0xa34e554f','0x2b59e402','0x837cef1e','0x2a379ea3','0xd1847537','0x98968f15']],['0x185c2eac7ee5076cda7248a1484a0b90abba08e3',0,['0x2def6620','0x076f2129','0xcad44b33','0x2e2d3122','0x8b0e9f3f','0x0dedd016','0x8c09a2f9','0xd045bbee','0x04d5bcfd']],['0x26d1f20959f645a85a22ae4c48d7335d990ef8a7',0,['0xcf1d14dc','0x9f593c33','0x82382e88','0x04c26712','0xe51f25c0','0x9c48a3c3','0x4966c27e','0x9f7414e9','0xd27fe916','0xa8312b1d','0x9e269b68']],['0xb9aeb0575381482d35252c1d084f990fcf3cbe0a',0,['0xf2fde38b','0x8da5cb5b']]];

//  return deployer.deploy(EgorasV3, deploy, [accounts[0]])

 

//  deployer.deploy(StakingFacet)
// deployer.deploy(StakingFacetStable);
 deployer.deploy(PriceOracleFacet);
//  deployer.deploy(ProductFacet);
//  deployer.deploy(DealersFacet);
//   deployer.deploy(ConvertFacet);
//  deployer.deploy(PancakeSwapFacet);
//  deployer.deploy(DiamondCutFacet);
  deployer.deploy(StakingFacetNew);
 deployer.deploy(ExFacet);

  deployer.deploy(OwnershipFacet).then(() => {
    const diamondCut = [
      // [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      // [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      // [PriceOracleFacet.address, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      //[MembershipFacet.address, FacetCutAction.Add, getSelectors(MembershipFacet)],
      
      // [StakingFacetStable.address, FacetCutAction.Add, getSelectors(StakingFacetStable)],
      // [DrawFundsFacet.address, FacetCutAction.Add, getSelectors(DrawFundsFacet)],
      
      // [ProductFacet.address, FacetCutAction.Add, getSelectors(ProductFacet)],
      //  [ConvertFacet.address, FacetCutAction.Add, getSelectors(ConvertFacet)],
      // [StakingFacet.address, FacetCutAction.Add, getSelectors(StakingFacet)],
      // [DealersFacet.address, FacetCutAction.Add, getSelectors(DealersFacet)],
      // [PancakeSwapFacet.address, FacetCutAction.Add, getSelectors(PancakeSwapFacet)],
      [PriceOracleFacet.address, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      [ExFacet.address, FacetCutAction.Add, getSelectors(ExFacet)],
      [ExFacet.address, FacetCutAction.Add, getSelectors(StakingFacetNew)],
      [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)],

    ]

       const diamondCut2 = [
      // [DiamondCutFacet.contractName, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      // [DiamondLoupeFacet.contractName, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      // [PriceOracleFacet.contractName, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      // [DealersFacet.contractName, FacetCutAction.Add, getSelectors(DealersFacet)],
      // [ProductFacet.contractName, FacetCutAction.Add, getSelectors(ProductFacet)],
      //  [ConvertFacet.contractName, FacetCutAction.Add, getSelectors(ConvertFacet)],
      // [StakingFacet.contractName, FacetCutAction.Add, getSelectors(StakingFacet)],
      // [StakingFacetStable.contractName, FacetCutAction.Add, getSelectors(StakingFacetStable)],
      // [DrawFundsFacet.contractName, FacetCutAction.Add, getSelectors(DrawFundsFacet)],
      [PriceOracleFacet.contractName, FacetCutAction.Add, getSelectors(PriceOracleFacet)],
      [ExFacet.contractName, FacetCutAction.Add, getSelectors(ExFacet)],
      [StakingFacetNew.contractName, FacetCutAction.Add, getSelectors(StakingFacetNew)],
      [OwnershipFacet.contractName, FacetCutAction.Add, getSelectors(OwnershipFacet)],
      
      // [PancakeSwapFacet.contractName, FacetCutAction.Add, getSelectors(PancakeSwapFacet)],
      // [OwnershipFacet.contractName, FacetCutAction.Add, getSelectors(OwnershipFacet)],
    ]

  console.log(diamondCut2);

    

    return deployer.deploy(EgorasV3, diamondCut, [accounts[0]])
 })
}
 