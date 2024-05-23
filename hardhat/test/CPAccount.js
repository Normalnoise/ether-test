const { expect } = require('chai')
const { ethers } = require('hardhat')

describe('CPAccount', function () {
  let CPAccount,
    cpAccount,
    owner,
    newOwner,
    worker,
    newWorker,
    beneficiary,
    newBeneficiary,
    contractRegistry,
    addr1

  beforeEach(async function () {
    // Get signers
    ;[
      owner,
      newOwner,
      worker,
      newWorker,
      beneficiary,
      newBeneficiary,
      contractRegistry,
      addr1,
    ] = await ethers.getSigners()

    // Deploy the CPAccount contract
    const CPAccountFactory = await ethers.getContractFactory('CPAccount')
    cpAccount = await CPAccountFactory.deploy(
      'node1',
      ['multiAddress1', 'multiAddress2'],
      beneficiary.address,
      worker.address,
      contractRegistry.address,
      [1, 2, 3],
    )

    await cpAccount.waitForDeployment()
  })

  it('Should deploy with correct parameters', async function () {
    expect(await cpAccount.owner()).to.equal(owner.address)
    expect(await cpAccount.worker()).to.equal(worker.address)
    expect(await cpAccount.beneficiary()).to.equal(beneficiary.address)
    expect(await cpAccount.contractRegistryAddress()).to.equal(
      contractRegistry.address,
    )
    expect(await cpAccount.nodeId()).to.equal('node1')
    expect(await cpAccount.multiAddresses(0)).to.equal('multiAddress1')
    expect(await cpAccount.multiAddresses(1)).to.equal('multiAddress2')
    expect(await cpAccount.taskTypes(0)).to.equal(1)
    expect(await cpAccount.taskTypes(1)).to.equal(2)
    expect(await cpAccount.taskTypes(2)).to.equal(3)
    expect(await cpAccount.VERSION()).to.equal('2.0')
  })

  it('Should allow the owner to transfer ownership', async function () {
    await cpAccount.changeOwnerAddress(newOwner.address)
    expect(await cpAccount.owner()).to.equal(newOwner.address)
  })

  it('Should not allow non-owner to transfer ownership', async function () {
    await expect(
      cpAccount.connect(addr1).changeOwnerAddress(newOwner.address),
    ).to.be.revertedWith('Only owner can call this function.')
  })

  it('Should allow the owner to change worker', async function () {
    await cpAccount.changeWorker(newWorker.address)
    expect(await cpAccount.worker()).to.equal(newWorker.address)
  })

  it('Should allow the owner to change multiAddresses', async function () {
    await cpAccount.changeMultiaddrs(['newAddress1', 'newAddress2'])
    expect(await cpAccount.multiAddresses(0)).to.equal('newAddress1')
    expect(await cpAccount.multiAddresses(1)).to.equal('newAddress2')
  })

  it('Should allow the owner to change beneficiary', async function () {
    await cpAccount.changeBeneficiary(newBeneficiary.address)
    expect(await cpAccount.beneficiary()).to.equal(newBeneficiary.address)
  })

  it('Should allow the owner to change task types', async function () {
    await cpAccount.changeTaskTypes([4, 5, 6])
    expect(await cpAccount.taskTypes(0)).to.equal(4)
    expect(await cpAccount.taskTypes(1)).to.equal(5)
    expect(await cpAccount.taskTypes(2)).to.equal(6)
  })
})
