/**
 * Use this file to configure your truffle project. It's seeded with some
 * common settings for different networks and features like migrations,
 * compilation and testing. Uncomment the ones you need or modify
 * them to suit your project as necessary.
 *
 * More information about configuration can be found at:
 *
 * trufflesuite.com/docs/advanced/configuration
 *
 * To deploy via Infura you'll need a wallet provider (like @truffle/hdwallet-provider)
 * to sign your transactions before they're sent to a remote public node. Infura accounts
 * are available for free at: infura.io/register.
 *
 * You'll also need a mnemonic - the twelve word phrase the wallet uses to generate
 * public/private key pairs. If you're publishing your code to GitHub make sure you load this
 * phrase from a file you've .gitignored so it doesn't accidentally become public.
 *
 */
 const HDWalletProvider = require("@truffle/hdwallet-provider");
 const {GENERAL_PRIVATE_KEY,PRIVATE_KEY,PRIVATE_KEY3, BSCSCAN_API_KEY, PRIVATE_KEY4} = require("./env.json");
 const privateKeys = [PRIVATE_KEY]
 const privateKeys3 = [PRIVATE_KEY3]
 const privateKeys4 = [PRIVATE_KEY4]
 const mainPrivateKey = [GENERAL_PRIVATE_KEY]
// const HDWalletProvider = require('@truffle/hdwallet-provider');
//
// const fs = require('fs');
// const mnemonic = fs.readFileSync(".secret").toString().trim();

module.exports = {
  /**
   * Networks define how you connect to your ethereum client and let you set the
   * defaults web3 uses to send transactions. If you don't specify one truffle
   * will spin up a development blockchain for you on port 9545 when you
   * run `develop` or `test`. You can ask a truffle command to use a specific
   * network from the command line, e.g
   *
   * $ truffle test --network <network-name>
   */
  api_keys: {
    bscscan: BSCSCAN_API_KEY
  },
  plugins: [
    'truffle-plugin-verify'
  ],
   networks: {
 
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 7545, // Standard Ethereum port (default: none)
      network_id: '*' // Any network (default: none)
    },
    bscMainNet: {
      provider: () => new HDWalletProvider(
        mainPrivateKey,
        //'https://bscrpc.com'
         //`wss://bsc-ws-node.nariox.org:443`
       // 'https://bsc-dataseed.binance.org'
        'https://bsc-dataseed1.ninicoin.io/'
     // 'https://bsc-dataseed1.defibit.io'
       //'https://bsc-dataseed.binance.org'
      // 'https://rpc.ankr.com/bsc'
      ),
      network_id: 56,
      skipDryRun: true
    },
 bscMainNetChidubem: {
      provider: () => new HDWalletProvider(
        privateKeys4,
        //'https://bscrpc.com'
        // `wss://bsc-ws-node.nariox.org:443`
       // 'https://bsc-dataseed.binance.org'
        'https://bsc-dataseed1.ninicoin.io/'
     // 'https://bsc-dataseed1.defibit.io'
       //'https://bsc-dataseed.binance.org'
       //'https://rpc.ankr.com/bsc'
      ),
     networkCheckTimeout: 10000, 
      network_id: 56,
      skipDryRun: true,
      timeoutBlocks: 2000
    },

    
  bscMainNetPythia: {
      provider: () => new HDWalletProvider(
        //pythia,
        privateKeys,
       // 'https://bsc-dataseed.binance.org'
        `wss://bsc-ws-node.nariox.org:443`
      ),
      network_id: 56,
      skipDryRun: true
    },
     
     bscTestNet3: {
       networkCheckTimeout: 10000, 
      provider: () => new HDWalletProvider(
        privateKeys3,
        
        //'https://data-seed-prebsc-1-s1.binance.org:8545/'
         // 'https://data-seed-prebsc-1-s2.binance.org:8545/'
        //'https://data-seed-prebsc-2-s3.binance.org:8545/'
        //`wss://data-seed-prebsc-1-s1.binance.org:8545`
        //'http://data-seed-prebsc-2-s2.binance.org:8545/'
       //'https://data-seed-prebsc-1-s3.binance.org:8545/'
       'https://rpc.ankr.com/bsc_testnet_chapel'
      ),
      network_id: 97,
      skipDryRun: true,
      timeoutBlocks: 2000
    },

    bscTestNet: {
       networkCheckTimeout: 10000, 
      provider: () => new HDWalletProvider(
        mainPrivateKey,
        
        //'https://data-seed-prebsc-1-s1.binance.org:8545/'
         // 'https://data-seed-prebsc-1-s2.binance.org:8545/'
        'https://data-seed-prebsc-2-s3.binance.org:8545/'
        //`wss://data-seed-prebsc-1-s1.binance.org:8545`
        //'http://data-seed-prebsc-2-s2.binance.org:8545/'
       //'https://data-seed-prebsc-1-s3.binance.org:8545/'
       //'https://bsc-testnet.drpc.org/'
      ),
      network_id: 97,
      skipDryRun: true,
      timeoutBlocks: 2000
    }

  },

 compilers: {
    solc: {
      version: "^0.8.0",
      settings: {
        evmVersion: 'byzantium' // Default: "petersburg"
      },
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },



  // Truffle DB is currently disabled by default; to enable it, change enabled:
  // false to enabled: true. The default storage location can also be
  // overridden by specifying the adapter settings, as shown in the commented code below.
  //
  // NOTE: It is not possible to migrate your contracts to truffle DB and you should
  // make a backup of your artifacts to a safe location before enabling this feature.
  //
  // After you backed up your artifacts you can utilize db by running migrate as follows: 
  // $ truffle migrate --reset --compile-all
  //
  // db: {
    // enabled: false,
    // host: "127.0.0.1",
    // adapter: {
    //   name: "sqlite",
    //   settings: {
    //     directory: ".db"
    //   }
    // }
  // }
};
