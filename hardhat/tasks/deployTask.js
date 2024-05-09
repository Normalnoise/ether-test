task('deployTask', 'Deploy Upgradeable ECP Task').setAction(async () => {
  let [owner, others] = await ethers.getSigners()

  const Task = await ethers.getContractFactory('ECPTask')
  console.log('Deploying Task Contract...')

  const task = await upgrades.deployProxy(Task, [], {
    initializer: 'initialize',
  })
  await task.waitForDeployment()
  console.log('Task Contract deployed to:', await task.getAddress())
})
