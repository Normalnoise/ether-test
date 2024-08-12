require('@nomicfoundation/hardhat-toolbox')
require('@openzeppelin/hardhat-upgrades')
require('./tasks/deployCollateral')
// require('./tasks/deployTask')
require('./tasks/upgradeAccount')
require('./tasks/upgradeCollateral')
require('./tasks/upgradeTask')
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.24',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
          viaIR: true,
        },
      },
      { version: '0.8.19' },
      { version: '0.8.20' },
      {
        version: '0.8.26',
        settings: {
          optimizer: {
            enabled: true,
            runs: 2000,
          },
          viaIR: true,
        },
      },
    ],
  },
  networks: {
    saturn: {
      url: process.env.SATURN_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    proxima: {
      url: process.env.PROXIMA_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
    mainnet: {
      url: process.env.SWAN_MAINNET_RPC_URL,
      accounts: [process.env.SWAN_MAINNET_PRIVATE_KEY],
    },
  },
}
