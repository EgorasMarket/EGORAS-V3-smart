import React, { Fragment, useEffect, useState } from "react";
import { BrowserRouter as Router, Routes, Route, Link } from "react-router-dom";
import 'bootstrap/dist/css/bootstrap.css';
import './App.css';
////////////////---UI---///////////////
import {
  Web3ReactProvider,
  useWeb3React,
  UnsupportedChainIdError,
} from "@web3-react/core";
import {
  NoEthereumProviderError,
  UserRejectedRequestError as UserRejectedRequestErrorInjected,
} from "@web3-react/injected-connector";
//import { UserRejectedRequestError as UserRejectedRequestErrorWalletConnect } from '@web3-react/walletconnect-connector';
//import { UserRejectedRequestError as UserRejectedRequestErrorFrame } from '@web3-react/frame-connector';
import { Web3Provider } from "@ethersproject/providers";
import { formatEther } from "@ethersproject/units";

import { useEagerConnect, useInactiveListener } from "./hooks";
import {
  injected,
  // network,
  // walletconnect,
  // walletlink,
  // ledger,
  // trezor,
  // frame,
  // authereum,
  // fortmatic,
  // portis,
  // squarelink,
  // torus
} from "./connectors";
import HomeUpdate from "./components/layout/HomeUpdate/HomeUpdate";
const App = () => {
  function getLibrary(provider) {
    const library = new Web3Provider(provider);
    library.pollingInterval = 8000;
    return library;
  }

  return (
    <Web3ReactProvider getLibrary={getLibrary}>
 <Router>
 <Fragment>
 <Routes>
                  <Route exact path="/" element={<HomeUpdate />} />
                  </Routes>
   </Fragment>
  </Router>
    </Web3ReactProvider>
  );
}

export default App;
