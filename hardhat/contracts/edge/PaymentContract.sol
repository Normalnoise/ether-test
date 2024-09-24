// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentContract is Ownable {
    IERC20 public token;  // ERC20 token contract address
    address public platformWallet;  // Platform wallet address
    uint256 public platformFeeRate;  // Platform fee rate, e.g., 3 shows 3%

    struct WalletAccount {
        uint256 available;  // User's available balance
        int256 escrow;  // User's Escrow account balance
        uint256 withdrawRequestAmount;  // Amount requested by the user for withdrawal
        uint256 withdrawRequestBlock;  // Block height when the user requested the withdrawal
    }

    mapping(address => WalletAccount) public accounts;  // Account information for each user
    mapping(address => bool) public admins;  // Admin privileges

    uint256 public blocksForWithdrawal;  // Dynamically set block confirmation wait time, in blocks

    // Events
    event RequestEscrowToAvailable(address indexed user, uint256 requestBlock, uint256 amount);
    event ConfirmEscrowToAvailable(address indexed user, uint256 amount);
    event BlocksForWithdrawalUpdated(uint256 newBlocksForWithdrawal);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event PlatformFeeRateSet(uint256 feeRate);
    event PlatformWalletSet(address indexed platformWallet);
    event TokenAddressSet(address indexed token);
    event TransferToCPBeneficiary(address account, address cpAccount, address beneficiary, uint256 transferAmount);
    event TransferToPlatform(address account, address platformWallet, uint256 realPlatformFee, uint256 platformFee);
    event Deposited(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);  // New event for withdrawals
    event transferedToEscrow(address indexed account, uint256 amount);



    modifier onlyAdmin() {
        require(admins[msg.sender], "Not an admin");
        _;
    }

    // Constructor: initializes platform wallet, platform fee rate, ERC20 token address, and initial block height
    constructor(address _tokenAddress, address _platformWallet, uint256 _platformFeeRate, uint256 _initialBlocksForWithdrawal) Ownable(msg.sender){
        token = IERC20(_tokenAddress);
        platformWallet = _platformWallet;
        platformFeeRate = _platformFeeRate;
        blocksForWithdrawal = _initialBlocksForWithdrawal;
        admins[msg.sender] = true;  // Default the contract deployer as an administrator
    }

    // 1. Change the contract's Owner
    function changeOwner(address newOwner) external onlyOwner {
        transferOwnership(newOwner);
    }

    // 2. Add an administrator
    function addAdmin(address admin) external onlyOwner {
        admins[admin] = true;
        emit AdminAdded(admin);
    }

    // 3. Remove an administrator
    function removeAdmin(address admin) external onlyOwner {
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    // 4. Set the platform fee rate
    function setPlatformFeeRate(uint256 _feeRate) external onlyOwner {
        platformFeeRate = _feeRate;
        emit PlatformFeeRateSet(_feeRate);
    }

    // 5. Set the platform wallet address
    function setPlatformWallet(address _wallet) external onlyOwner {
        platformWallet = _wallet;
        emit PlatformWalletSet(_wallet);
    }

    // 6. Set the ERC20 Token address
    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = IERC20(_tokenAddress);
        emit TokenAddressSet(_tokenAddress);
    }

    // 7. Set new block confirmation height (only settable by Owner)
    function setBlocksForWithdrawal(uint256 newBlocksForWithdrawal) external onlyOwner {
        require(newBlocksForWithdrawal > 0, "Blocks for withdrawal must be greater than zero");
        blocksForWithdrawal = newBlocksForWithdrawal;
        emit BlocksForWithdrawalUpdated(newBlocksForWithdrawal);
    }

    // 8. Deposit to Available account
    function deposit(uint256 amount) external {
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        accounts[msg.sender].available += amount;
        emit Deposited(msg.sender, amount);
    }

    // 9. transfer to Escrow account
    function transferToEscrow(uint256 amount) external {
        require(accounts[msg.sender].available > amount, "Insufficient fund to transfer");
        accounts[msg.sender].available -= amount;
        accounts[msg.sender].escrow += int256(amount);
        emit transferedToEscrow(msg.sender, amount);
    }


    // 10. Withdraw from Available account to wallet
    function withdrawAvailableToWallet(uint256 amount) external {
        require(accounts[msg.sender].available >= amount, "Insufficient balance");
        accounts[msg.sender].available -= amount;
        require(token.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawal(msg.sender, amount);  // Emit the Withdrawal event after a successful transfer
    }

    // 11. Request withdrawal from Escrow account to Available account (only records the withdrawal amount and request block height)
    function requestWithdrawEscrowToAvailable(uint256 amount) external {
        require(accounts[msg.sender].escrow >= int256(amount), "Insufficient Escrow balance");
        require(amount > 0, "Withdrawal amount must be greater than zero");

        // Record the withdrawal amount and current block height
        accounts[msg.sender].withdrawRequestAmount = amount;
        accounts[msg.sender].withdrawRequestBlock = block.number;

        emit RequestEscrowToAvailable(msg.sender, block.number, amount);
    }

    // 12. Confirm Escrow withdrawal to Available account (based on block height confirmation, actual fund transfer)
    function confirmWithdrawEscrowToAvailable() external {
        require(accounts[msg.sender].withdrawRequestBlock > 0, "No withdrawal request");
        require(block.number >= accounts[msg.sender].withdrawRequestBlock + blocksForWithdrawal, "Withdrawal not yet available based on block height");
        require(accounts[msg.sender].withdrawRequestAmount > 0, "No withdrawal amount recorded");

        // Actual fund transfer operation: transfer Escrow amount to Available account
        uint256 amount = accounts[msg.sender].withdrawRequestAmount;
        accounts[msg.sender].escrow -= int256(amount);
        accounts[msg.sender].available += amount;

        // Clear the completed withdrawal request
        accounts[msg.sender].withdrawRequestAmount = 0;
        accounts[msg.sender].withdrawRequestBlock = 0;

        emit ConfirmEscrowToAvailable(msg.sender, amount);
    }

    // 13. Admin transfers part of a user's Escrow funds to a CP account's beneficiary address
    function transferEscrowToCPBeneficiary(address account, address cpAccount, uint256 amount) internal onlyAdmin {
        int256 escrowBalance = accounts[account].escrow;  // Get the current escrow balance

        // If escrow is insufficient, only pay the escrow balance, allowing balance to go negative
        uint256 transferAmount = escrowBalance >= int256(amount) ? amount : uint256(escrowBalance);  // Calculate actual transfer amount

        // Deduct funds from escrow, allowing balance to go negative
        accounts[account].escrow -= int256(amount);

        // Call cpAccount's getBeneficiary function, get the beneficiary address
        (bool success, bytes memory CPBeneficiary) = cpAccount.call(abi.encodeWithSignature("getBeneficiary()"));
        require(success, "Failed to call getBeneficiary function of CPAccount");

        // Decode the returned beneficiary address
        address beneficiary = abi.decode(CPBeneficiary, (address));

        // Perform transfer to beneficiary, pay the actual calculated transferAmount
        require(token.transfer(beneficiary, transferAmount), "Transfer to beneficiary failed");

        emit TransferToCPBeneficiary(account, cpAccount, beneficiary, transferAmount);
    }

    // 14. Batch transfer amounts from users to CP's beneficiary address, deducting platform fee
    function batchPaymentToCP(
        address[] memory users,
        address[] memory cps,
        uint256[] memory amounts
    ) external onlyAdmin {
        require(users.length == cps.length && users.length == amounts.length, "Mismatched input arrays");

        for (uint256 i = 0; i < users.length; i++) {
            // Calculate the platform fee
            uint256 platformFee = (amounts[i] * platformFeeRate) / 100;
            int256 escrowBalance = accounts[users[i]].escrow;  // Get the current user's escrow balance

            // If deducting the platform fee results in insufficient escrow, deduct the remaining balance and allow escrow to go negative
            uint256 realPlatformFee = escrowBalance >= int256(platformFee) ? platformFee : uint256(escrowBalance);  // Calculate actual platformFee

            // Deduct the platform fee and transfer it to the platform wallet
            accounts[users[i]].escrow -= int256(platformFee);
            require(token.transfer(platformWallet, realPlatformFee), "Transfer of platform fee to platform wallet failed");

            // Call transferEscrowToCPBeneficiary function to transfer remaining funds to CP's beneficiary
            uint256 remainingAmount = amounts[i] - realPlatformFee;
            transferEscrowToCPBeneficiary(users[i], cps[i], remainingAmount);

            emit TransferToPlatform(users[i], platformWallet, realPlatformFee, platformFee);
        }
    }

    // Query the account balance of a single wallet, including available and escrow
    function getAccountBalance(address wallet) external view returns (uint256 available, int256 escrow) {
        WalletAccount storage account = accounts[wallet];
        return (account.available, account.escrow);
    }

    // Function to get basic contract information
    function getBasicInfo() external view returns (address tokenAddress, address platformAddress, uint256 feeRate, uint256 withdrawalBlocks) {
        return (address(token), platformWallet, platformFeeRate, blocksForWithdrawal);
    }
}
