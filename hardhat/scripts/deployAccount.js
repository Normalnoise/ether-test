const { ethers, upgrades } = require('hardhat')

const NODE_ID = ''
const MULTI_ADDRESSES = []
const BENEFICIARY = '0x..'
const WORKER = '0x..'
const CONTRACT_REGISTRY_ADDRESS = '0x..'
const TASK_TYPES = []

async function main() {
  let [owner, others] = await ethers.getSigners()

  const CPAccountUpgradeable = await ethers.getContractFactory(
    'CPAccountUpgradeable',
  )

  console.log('Deploying CPAccount Contract...')
  const cpAccount = await upgrades.deployProxy(
    CPAccountUpgradeable,
    [
      NODE_ID,
      MULTI_ADDRESSES,
      BENEFICIARY,
      WORKER,
      CONTRACT_REGISTRY_ADDRESS,
      TASK_TYPES,
    ],
    {
      initializer: 'initialize',
    },
  )
  await cpAccount.waitForDeployment()
  console.log(
    'Upgradeable CP Account Contract deployed to:',
    await cpAccount.getAddress(),
  )
}

main()
