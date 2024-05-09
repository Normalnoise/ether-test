task('upgradeCollateral', 'Upgrade an existing ECP Collateral contract')
  .addPositionalParam('address', 'ECPCollateral address')
  .setAction(async ({ address }) => {
    const ECPCollateralContract = await ethers.getContractFactory(
      'ECPCollateralContract',
    )

    console.log('Upgrading ECPCollateral...')
    const ECP = await upgrades.upgradeProxy(address, ECPCollateralContract)
    console.log('ECPCollateral upgraded successfully')
  })
