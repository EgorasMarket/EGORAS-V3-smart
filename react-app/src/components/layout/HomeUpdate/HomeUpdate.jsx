import React, { useState, useEffect } from "react";

import Header from "../Header/Header";
import EgorasSwapFacet from '../../../build/contracts/EgorasSwapFacet';
import {
  Web3ReactProvider,
  useWeb3React,
  UnsupportedChainIdError
} from "@web3-react/core";
const HomeUpdate = () => {
  const context = useWeb3React();
  const {
    connector,
    library,
    chainId,
    account,
    activate,
    deactivate,
    active,
    error
  } = context;
  function getSelectors (contract) {
    const selectors = contract.abi.reduce((acc, val) => {
      if (val.type === 'function') {
        acc.push(val.signature)
        return acc
      } else {
        return acc
      }
    }, [])
    return selectors
  }
  const deployContract = async () =>{
  //   console.log("Ello", EgorasSwapFacet.abi)
  //  let acc = getSelectors(EgorasSwapFacet);
  //  console.log("Ello", acc)
   // ContractFactory
console.log(library);

  }

  return (
    <div style={{ overflow: "hidden" }}>
    <Header />
      

      <div className="col-md-6 mt-6 ml-auto" style={{margin: "auto"}}>
          <div className="text-center wrapper">
              <button className="btn btn-info" onClick={deployContract}>
                Upgrade
              </button>
          </div>
      </div>
    </div>
  );
};

export default HomeUpdate;
