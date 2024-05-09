task('upgradeAccount', 'Upgrade an existing CP Account contract')
  .addPositionalParam('account', 'CPAccount address')
  .setAction(async ({ account }) => {
    const CPAccountUpgradeable = await ethers.getContractFactory(
      'CPAccountUpgradeable',
    )

    console.log('Deploying Payment Contract...')
    const cpAccount = await upgrades.upgradeProxy(account, CPAccountUpgradeable)
    console.log('CP Account upgraded successfully')
  })
