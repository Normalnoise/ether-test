// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ECPCollateral is Ownable {
    uint public slashedFunds;
    uint public taskCapacity;
    uint public taskBalance;

    mapping(address => bool) public isAdmin;
    mapping(address => int) public balances;
    mapping(address => uint) public frozenBalance;
    mapping(address => string) public cpStatus;

    struct CPInfo {
        address cp;
        int balance;
        uint frozenBalance;
        string status;
    }

    event Deposit(address fundingWallet, address receivingWallet, uint depositAmount);
    event Withdraw(address fundingWallet, uint withdrawAmount);
    event LockCollateral(address cp, uint collateralAmount);
    event UnlockCollateral(address cp, uint collateralAmount);
    event SlashCollateral(address cp, uint amount);
    event DisputeProof(address disputer, string proofTx);
    

    constructor() Ownable(msg.sender) {
        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function addAdmin(address newAdmin) public onlyOwner {
        isAdmin[newAdmin] = true;
    }

    function removeAdmin(address admin) public onlyOwner {
        isAdmin[admin] = false;
    }

    function setTaskCapacity(uint capacity) public onlyAdmin {
        taskCapacity = capacity;
    }  

    function getTaskCapacity() public pure returns (uint) {
        return taskCapacity;
    }

    function cpInfo(address cpAddress) public view returns (CPInfo memory) {
        CPInfo memory info;

        info.cp = cpAddress;
        info.balance = balances[cpAddress];
        info.frozenBalance = frozenBalance[cpAddress];
        info.status = cpStatus[cpAddress];

        return info;
    }

    function checkCpInfo(address cpAddress) internal {
        if (balances[cpAddress] >= int(5*taskCapacity)) {
            cpStatus[cpAddress] = 'zkAuction';
        } else {
            cpStatus[cpAddress] = 'NSC';
        }
    }

    receive() external payable {
        deposit(msg.sender);
    }

    /**
     * @notice - deposits tokens into the contract
     */
    function deposit(address recipient) public payable {
        balances[recipient] += int(msg.value);

        checkCpInfo(recipient);

        emit Deposit(msg.sender, recipient, msg.value);
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= int(amount), "Withdraw amount exceeds balance");

        balances[msg.sender] -= int(amount);
        payable(msg.sender).transfer(amount);

        checkCpInfo(msg.sender);

        emit Withdraw(msg.sender, amount);
    }

    function batchLockCollateral(address[] memory cpList, uint collateral) public onlyAdmin {
        for (uint i = 0; i < cpList.length; i++) {
            require(balances[cpList[i]] >= int(collateral), 'Not enough balance for collateral');
        }

        for (uint i = 0; i < cpList.length; i++) {
            balances[cpList[i]] -= int(collateral);
            frozenBalance[cpList[i]] += collateral;

            checkCpInfo(cpList[i]);


            emit LockCollateral(cpList[i], collateral);
        }

        uint totalCollateral = cpList.length * collateral;
        taskBalance += totalCollateral;
    }

    function lockCollateral(address cp, uint collateral) public onlyAdmin {
            require(balances[cp] >= int(collateral), 'Not enough balance for collateral');
            balances[cp] -= int(collateral);
            frozenBalance[cp] += collateral;

            checkCpInfo(cp);
        

        uint totalCollateral = collateral;
        taskBalance += totalCollateral;

        emit LockCollateral(cp, collateral);
    }
    
    function unlockCollateral(address recipient, uint amount) public onlyAdmin {
        require(taskBalance >= amount, "Insufficient balance in task contract");

        // frozen balance is non negative
        if (frozenBalance[recipient] <= amount) {
            amount = frozenBalance[recipient];
        }
        
        taskBalance -= amount;
        frozenBalance[recipient] -= amount;
        balances[recipient] += int(amount);

        checkCpInfo(recipient);

        emit UnlockCollateral(recipient, amount);
    }

    function slashCollateral(address cp) public onlyAdmin {
        uint slashAmount = taskCapacity * 2;
        balances[cp] -= int(slashAmount);

        slashedFunds += slashAmount;

        emit SlashCollateral(cp, slashAmount);
    }

    function disputeProof(string memory proofTx) public {
        emit DisputeProof(msg.sender, proofTx);
    }

    function withdrawSlashedFunds() public onlyOwner {
        uint amount = slashedFunds;
        slashedFunds = 0;

        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }
}
