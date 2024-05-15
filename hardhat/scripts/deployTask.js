const { ethers, upgrades } = require('hardhat')

/** 
    uint _taskType,
    uint _resourceType,
    string memory _inputParam,
    string memory _verifyParam,
    address _cpContractAddress,
    string memory _status,
    string memory _lockFundTx,
    uint _deadline
*/

const TASK_TYPE = 0
const RESOURCE_TYPE = 0
const INPUT_PARAM = ''
const VERIFY_PARAM = ''
const CP_CONTRACT_ADDRESS = '0x..'
const STATUS = ''
const LOCK_FUND_TX = ''
const DEADLINE = 0

async function main() {
  let [owner, others] = await ethers.getSigners()

  const ECPTaskUpgradeable = await ethers.getContractFactory(
    'ECPTaskUpgradeable',
  )
  console.log('Deploying Task Contract...')

  const task = await upgrades.deployProxy(
    ECPTaskUpgradeable,
    [
      TASK_TYPE,
      RESOURCE_TYPE,
      INPUT_PARAM,
      VERIFY_PARAM,
      CP_CONTRACT_ADDRESS,
      STATUS,
      LOCK_FUND_TX,
      DEADLINE,
    ],
    {
      initializer: 'initialize',
    },
  )
  await cpAccount.waitForDeployment()
  console.log(
    'Upgradeable ECP Task Contract deployed to:',
    await task.getAddress(),
  )
}

main()
