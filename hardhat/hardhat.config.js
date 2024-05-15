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
      { version: '0.8.24' },
      { version: '0.8.19' },
      { version: '0.8.20' },
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
  },
}
