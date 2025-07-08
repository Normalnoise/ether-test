require('@nomicfoundation/hardhat-toolbox')
require('@openzeppelin/hardhat-upgrades')
require('./tasks/deployCollateral')
// require('./tasks/deployTask')
require('./tasks/upgradeAccount')
require('./tasks/upgradeCollateral')
require('./tasks/upgradeTask')
require('dotenv').config()
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.26',
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      { version: '0.8.24' },
      { version: '0.8.19' },
      { version: '0.8.20' },
    ],
  },
  networks: {
    // saturn: {
    //   url: process.env.SATURN_RPC,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    // proxima: {
    //   url: process.env.PROXIMA_RPC,
    //   accounts: [process.env.PRIVATE_KEY],
    // },
    swan: {
      url: 'https://mainnet-rpc.swanchain.org',
      accounts: [],
    },
  },
    etherscan: {
      apiKey: {
        swan: 'swan',
      },
      customChains: [
        {
          network: 'swan',
          chainId: 254,
          urls: {
            apiURL:
              'https://api.routescan.io/v2/network/mainnet/evm/254/etherscan',
            browserURL: 'https://swan.thesuperscan.io',
          },
        },
      ],
    },
}
