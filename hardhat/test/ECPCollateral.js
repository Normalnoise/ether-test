const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('ECPCollateral', function () {
  let ECPCollateral,
    ecpCollateral,
    owner,
    admin,
    newAdmin,
    cpAccount,
    benficiary,
    worker,
    contractRegistry,
    cpAccountContract,
    taskContract,
    addr1

  beforeEach(async function () {
    ;[
      owner,
      admin,
      newAdmin,
      cpAccount,
      benficiary,
      worker,
      contractRegistry,
      taskContract,
      addr1,
    ] = await ethers.getSigners()

    const ECPCollateralFactory = await ethers.getContractFactory(
      'ECPCollateral',
    )
    ecpCollateral = await ECPCollateralFactory.deploy()
    await ecpCollateral.waitForDeployment()
  })

  it('Should initialize with correct owner and default values', async function () {
    expect(await ecpCollateral.owner()).to.equal(owner.address)
    expect(await ecpCollateral.collateralRatio()).to.equal(5)
    expect(await ecpCollateral.slashRatio()).to.equal(2)
    expect(await ecpCollateral.isAdmin(owner.address)).to.be.true
  })

  it('Should allow owner to add and remove admin', async function () {
    await ecpCollateral.addAdmin(admin.address)
    expect(await ecpCollateral.isAdmin(admin.address)).to.be.true

    await ecpCollateral.removeAdmin(admin.address)
    expect(await ecpCollateral.isAdmin(admin.address)).to.be.false
  })

  it('Should allow deposit and update balance', async function () {
    await ecpCollateral
      .connect(cpAccount)
      .deposit(cpAccount.address, { value: ethers.parseEther('1') })
    expect(await ecpCollateral.balances(cpAccount.address)).to.equal(
      ethers.parseEther('1'),
    )
  })

  it('Should allow admin to lock collateral', async function () {
    await ecpCollateral.addAdmin(admin.address)
    await ecpCollateral.setBaseCollateral(ethers.parseEther('0.1'))
    await ecpCollateral
      .connect(cpAccount)
      .deposit(cpAccount.address, { value: ethers.parseEther('1') })

    await ecpCollateral
      .connect(admin)
      .lockCollateral(cpAccount.address, taskContract.address)
    const task = await ecpCollateral.tasks(taskContract.address)

    const expectedCollateral = ethers.parseEther('0.5') // collateralRatio (5) * baseCollateral (0.1)
    expect(task.cpAccountAddress).to.equal(cpAccount.address)
    expect(task.collateral).to.equal(expectedCollateral)
    expect(task.status).to.equal(1)
    expect(await ecpCollateral.frozenBalance(cpAccount.address)).to.equal(
      expectedCollateral,
    )
  })

  it('Should allow admin to unlock collateral', async function () {
    await ecpCollateral.addAdmin(admin.address)
    await ecpCollateral.setBaseCollateral(ethers.parseEther('0.1'))
    await ecpCollateral
      .connect(cpAccount)
      .deposit(cpAccount.address, { value: ethers.parseEther('1') })

    await ecpCollateral
      .connect(admin)
      .lockCollateral(cpAccount.address, taskContract.address)
    await ecpCollateral.connect(admin).unlockCollateral(taskContract.address)

    const task = await ecpCollateral.tasks(taskContract.address)

    expect(task.status).to.equal(2)
    expect(await ecpCollateral.balances(cpAccount.address)).to.equal(
      ethers.parseEther('1'),
    )
    expect(await ecpCollateral.frozenBalance(cpAccount.address)).to.equal(0)
  })

  it('Should allow admin to slash collateral and handle excess collateral correctly', async function () {
    await ecpCollateral.addAdmin(admin.address)
    await ecpCollateral.setBaseCollateral(ethers.parseEther('0.1'))
    await ecpCollateral
      .connect(cpAccount)
      .deposit(cpAccount.address, { value: ethers.parseEther('2') })
    await ecpCollateral
      .connect(admin)
      .lockCollateral(cpAccount.address, taskContract.address)
    await ecpCollateral.connect(admin).slashCollateral(taskContract.address)

    const task = await ecpCollateral.tasks(taskContract.address)

    expect(task.status).to.equal(2)
    expect(await ecpCollateral.slashedFunds()).to.equal(
      ethers.parseEther('0.2'),
    ) // baseCollateral (0.1) * slashRatio (2)
    expect(await ecpCollateral.balances(cpAccount.address)).to.equal(
      ethers.parseEther('1.8'),
    )
    expect(await ecpCollateral.frozenBalance(cpAccount.address)).to.equal(0)
  })

  it('Should allow owner to set collateral and slash ratios', async function () {
    await ecpCollateral.setCollateralRatio(10)
    await ecpCollateral.setSlashRatio(5)

    expect(await ecpCollateral.collateralRatio()).to.equal(10)
    expect(await ecpCollateral.slashRatio()).to.equal(5)
  })

  it('Should allow owner to set and get base collateral', async function () {
    await ecpCollateral.setBaseCollateral(ethers.parseEther('1'))

    expect(await ecpCollateral.getBaseCollateral()).to.equal(
      ethers.parseEther('1'),
    )
  })

  it('Should allow withdrawal by CP owner', async function () {
    const CPAccountFactory = await ethers.getContractFactory(
      'CPAccount',
      cpAccount,
    )
    cpAccountContract = await CPAccountFactory.deploy(
      'node1',
      ['multiAddress1', 'multiAddress2'],
      benficiary.address,
      worker.address,
      contractRegistry.address,
      [1, 2, 3],
    )

    await cpAccountContract.waitForDeployment()

    await ecpCollateral
      .connect(cpAccount)
      .deposit(cpAccountContract.target, { value: ethers.parseEther('2') })

    await ecpCollateral
      .connect(cpAccount)
      .withdraw(cpAccountContract.target, ethers.parseEther('1'))

    expect(await ecpCollateral.balances(cpAccountContract.target)).to.equal(
      ethers.parseEther('1'),
    )
  })

  it('Should allow owner to withdraw slashed funds', async function () {
    await ecpCollateral.addAdmin(admin.address)
    await ecpCollateral.setBaseCollateral(ethers.parseEther('0.1'))
    await ecpCollateral
      .connect(cpAccount)
      .deposit(cpAccount.address, { value: ethers.parseEther('2') })

    await ecpCollateral
      .connect(admin)
      .lockCollateral(cpAccount.address, taskContract.address)
    await ecpCollateral.connect(admin).slashCollateral(taskContract.address)

    const initialOwnerBalance = await ethers.provider.getBalance(owner.address)
    await ecpCollateral
      .connect(owner)
      .withdrawSlashedFunds(ethers.parseEther('0.2'))
    const finalOwnerBalance = await ethers.provider.getBalance(owner.address)

    expect(finalOwnerBalance - initialOwnerBalance).to.be.closeTo(
      ethers.parseEther('0.2'),
      ethers.parseEther('0.01'),
    ) // accounting for gas fees
  })
})
