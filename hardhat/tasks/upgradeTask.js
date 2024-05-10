task('upgradeTask', 'Upgrade an existing ECP Task contract')
  .addPositionalParam('address', 'ECPTask address')
  .setAction(async ({ address }) => {
    const ECPTask = await ethers.getContractFactory('ECPTask')

    console.log('Upgrading ECPTask...')
    const task = await upgrades.upgradeProxy(address, ECPTask)
    console.log('ECPTask upgraded successfully')
  })
