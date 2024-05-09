require('@nomicfoundation/hardhat-toolbox')
require('@openzeppelin/hardhat-upgrades')
require('./tasks/upgradeAccount')
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.24',
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
