task('deployCollateral', 'Deploy Upgradeable ECP Collateral').setAction(
  async () => {
    let [owner, others] = await ethers.getSigners()

    const Collateral = await ethers.getContractFactory(
      'ECPCollateralUpgradeable',
    )

    console.log('Deploying Collateral Contract...')

    const collateral = await upgrades.deployProxy(Collateral, [], {
      initializer: 'initialize',
    })
    await collateral.waitForDeployment()
    console.log(
      'Collateral Contract deployed to:',
      await collateral.getAddress(),
    )
  },
)
