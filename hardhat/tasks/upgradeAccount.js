task('upgradeAccount', 'Upgrade an existing CP Account contract')
  .addPositionalParam('address', 'CPAccount address')
  .setAction(async ({ address }) => {
    const CPAccountUpgradeable = await ethers.getContractFactory(
      'CPAccountUpgradeable',
    )

    console.log('Upgrading CP Account Contract...')
    const cpAccount = await upgrades.upgradeProxy(address, CPAccountUpgradeable)
    console.log('CP Account upgraded successfully')
  })
