// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ECPCollateral is Ownable {
    IERC20 public collateralToken;
    uint public slashedFunds;
    uint public baseCollateral;
    uint public collateralRatio;
    uint public slashRatio;

    mapping(address => bool) public isAdmin;
    mapping(address => int) public balances;
    mapping(address => uint) public frozenBalance;
    mapping(address => string) public cpStatus;
    

    struct ContractInfo {
        address collateralToken; 
        uint slashedFunds;
        uint baseCollateral;
        uint collateralRatio;
        uint slashRatio;
    }

    struct CPInfo {
        address cp;
        int balance;
        uint frozenBalance;
        string status;
    }

    event Deposit(address indexed fundingWallet, address indexed cpAccount, uint depositAmount);
    event Withdraw(address indexed cpOwner, address indexed cpAccount, uint withdrawAmount);
    event WithdrawSlash(address indexed collateralContratOwner, uint slashfund);
    event CollateralLocked(address indexed cp, uint collateralAmount);
    event CollateralUnlocked(address indexed cp, uint collateralAmount);
    event CollateralSlashed(address indexed cp, uint amount);
    event CollateralAdjusted(address indexed cp, uint frozenAmount, uint balanceAmount, string operation);
    event DisputeProof(address indexed challenger, address indexed taskContractAddress, address cpAccount, uint taskID);


    constructor() Ownable(msg.sender) {
        _transferOwnership(msg.sender);
        isAdmin[msg.sender] = true;
        collateralRatio = 5; // Default collateral ratio
        slashRatio = 2; // Default slash ratio
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function addAdmin(address newAdmin) external onlyOwner {
        isAdmin[newAdmin] = true;
    }

    function removeAdmin(address admin) external onlyOwner {
        isAdmin[admin] = false;
    }

    function lockCollateral(address cp, uint taskCollateral) public onlyAdmin {
        require(balances[cp] >= int(taskCollateral), "Not enough balance for collateral");
        balances[cp] -= int(taskCollateral);
        frozenBalance[cp] += taskCollateral;
        checkCpInfo(cp);
        emit CollateralLocked(cp, taskCollateral);
    }

    function unlockCollateral(address cp, uint taskCollateral) public onlyAdmin {
        uint availableAmount = frozenBalance[cp];
        uint unlockAmount = taskCollateral > availableAmount ? availableAmount : taskCollateral;

        frozenBalance[cp] -= unlockAmount;
        balances[cp] += int(unlockAmount);
        checkCpInfo(cp);
        emit CollateralUnlocked(cp, unlockAmount);
    }

    function slashCollateral(address cp, uint slashAmount) public onlyAdmin {
        uint availableFrozen = frozenBalance[cp];
        uint fromFrozen = slashAmount > availableFrozen ? availableFrozen : slashAmount;
        uint fromBalance = slashAmount > fromFrozen ? slashAmount - fromFrozen : 0;
        frozenBalance[cp] -= fromFrozen;
        balances[cp] -= int(fromBalance);
        slashedFunds += slashAmount;
        checkCpInfo(cp);
        emit CollateralSlashed(cp, slashAmount);
        emit CollateralAdjusted(cp, fromFrozen, fromBalance, "Slashed");
    }

    function batchLock(address[] calldata cps, uint[] calldata taskCollaterals) external onlyAdmin {
        require(cps.length == taskCollaterals.length, "Array lengths must match");

        for (uint i = 0; i < cps.length; i++) {
            lockCollateral(cps[i], taskCollaterals[i]);
        }
    }

    function batchUnlock(address[] calldata cps, uint[] calldata taskCollaterals) external onlyAdmin {
        require(cps.length == taskCollaterals.length, "Array lengths must match");
        for (uint i = 0; i < cps.length; i++) {
            unlockCollateral(cps[i], taskCollaterals[i]);
        }
    }

    function batchSlash(address[] calldata cps, uint[] calldata slashAmounts) external onlyAdmin {
        for (uint i = 0; i < cps.length; i++) {
            slashCollateral(cps[i], slashAmounts[i]);
        }
    }

    function disputeProof(address taskContractAddress, address cpAccount, uint taskID) public {
        emit DisputeProof(msg.sender, taskContractAddress, cpAccount, taskID);
    }


    function deposit(address cpAccount, uint amount) public {
        collateralToken.transferFrom(msg.sender, address(this), amount);
        balances[cpAccount] += int(amount);
        emit Deposit(msg.sender, cpAccount, amount);
        checkCpInfo(cpAccount);
    }

    function withdraw(address cpAccount, uint amount) external {
        (bool success, bytes memory CPOwner) = cpAccount.call(abi.encodeWithSignature("getOwner()"));
        require(success, "Failed to call getOwner function of CPAccount");
        address cpOwner = abi.decode(CPOwner, (address));
        require(balances[cpAccount] >= int(amount), "Withdraw amount exceeds balance");
        require(msg.sender == cpOwner, "Only CP's owner can withdraw the collateral funds");
        balances[cpAccount] -= int(amount);
        // payable(msg.sender).transfer(amount);
        collateralToken.transfer(msg.sender, amount);

        checkCpInfo(cpAccount);
        emit Withdraw(msg.sender, cpAccount, amount);

    }

    function getECPCollateralInfo() external view returns (ContractInfo memory) {
        return ContractInfo({
            collateralToken: address(collateralToken), 
            slashedFunds: slashedFunds,
            baseCollateral: baseCollateral,
            collateralRatio: collateralRatio,
            slashRatio: slashRatio
        });
    }

    function setCollateralToken(address tokenAddress) external onlyOwner {
        collateralToken = IERC20(tokenAddress);
    }

    function setCollateralRatio(uint _collateralRatio) external onlyOwner {
        collateralRatio = _collateralRatio;
    }

    function setSlashRatio(uint _slashRatio) external onlyOwner {
        slashRatio = _slashRatio;
    }

    function setBaseCollateral(uint _baseCollateral) external onlyAdmin {
        baseCollateral = _baseCollateral;
    }

    function getBaseCollateral() external view returns (uint) {
        return baseCollateral;
    }

    function cpInfo(address cpAccount) external view returns (CPInfo memory) {
        return CPInfo({
            cp: cpAccount,
            balance: balances[cpAccount],
            frozenBalance: frozenBalance[cpAccount],
            status: cpStatus[cpAccount]
        });
    }

    function checkCpInfo(address cpAccount) internal {
        if (balances[cpAccount] >= int(collateralRatio * baseCollateral)) {
            cpStatus[cpAccount] = 'zkAuction';
        } else {
            cpStatus[cpAccount] = 'NSC';
        }
    }


    function withdrawSlashedFunds(uint slashfund) public onlyOwner {
        require(slashedFunds >= slashfund, "Withdraw slashfund amount exceeds slashedFunds");
        slashedFunds -= slashfund;
        collateralToken.transfer(msg.sender, slashfund);
        emit WithdrawSlash(msg.sender, slashfund);
    }

}
