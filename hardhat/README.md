# CP Account

```shell
npm install
```

## Configure .env file

Use the `.env.example` file as reference

## Deploying a new upgradeable CP Account

First configure the constructor params in `scripts/deployAccount.js`

```js
const NODE_ID = ''
const MULTI_ADDRESSES = []
const BENEFICIARY = '0x..'
const WORKER = '0x..'
const CONTRACT_REGISTRY_ADDRESS = '0x..'
const TASK_TYPES = []
```

then run `npx hardhat run scripts/deployAccount.js --network <saturn|proxima>` depending on the chain you want to deploy to.

## Upgrade an existing upgradeable CP Account

Modify the contract code in `./contracts/CPAccountUpgradeable.sol`. Be mindful of the restrictions described here: https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable#modifying-your-contracts

After you save your changes, run `npx hardhat compile` to compile the contract and check for any errors

To upgrade, run `npx hardhat upgradeAccount <contract_address> --network <saturn|proxima>`
