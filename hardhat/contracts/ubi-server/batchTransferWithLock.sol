// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract BatchTransferWithLock {
    address public owner;
    address public tokenAddress;
    mapping(address => bool) public admins;

    // Locked funds for each address
    mapping(address => uint256) public lockedFunds;
    address[] public lockedRecipients; // Stores all addresses with locked funds

    uint256 public lockPercentage; // Global lock percentage

    event TransferPerformed(address indexed from, address indexed to, uint256 amount);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event TokenAddressUpdated(address indexed oldTokenAddress, address indexed newTokenAddress);
    event LockPercentageUpdated(uint256 oldLockPercentage, uint256 newLockPercentage);
    event FundsLocked(address indexed recipient, uint256 amount);
    event FundsClaimed(address indexed recipient, uint256 amount);
    event AllLockedFundsReleased(address indexed contractAddress, uint256 totalAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Only admin can perform this action");
        _;
    }

    constructor(address _tokenAddress, uint256 _lockPercentage) {
        require(_lockPercentage <= 100, "Invalid lock percentage");
        owner = msg.sender;
        tokenAddress = _tokenAddress;
        lockPercentage = _lockPercentage;
        admins[msg.sender] = true; // Initialize the contract creator as an admin
    }

    function addAdmin(address admin) external onlyOwner {
        require(admin != address(0), "Invalid address");
        admins[admin] = true;
        emit AdminAdded(admin);
    }

    function removeAdmin(address admin) external onlyOwner {
        require(admins[admin], "Admin does not exist");
        admins[admin] = false;
        emit AdminRemoved(admin);
    }

    function changeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        emit OwnerChanged(owner, newOwner);
        owner = newOwner;
    }

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        require(newTokenAddress != address(0), "Invalid token address");
        emit TokenAddressUpdated(tokenAddress, newTokenAddress);
        tokenAddress = newTokenAddress;
    }

    function setLockPercentage(uint256 newLockPercentage) external onlyOwner {
        require(newLockPercentage <= 100, "Invalid lock percentage");
        emit LockPercentageUpdated(lockPercentage, newLockPercentage);
        lockPercentage = newLockPercentage;
    }

    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external onlyAdmin {
        require(recipients.length == amounts.length, "Mismatched arrays");
        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]), "Transfer failed");
            emit TransferPerformed(msg.sender, recipients[i], amounts[i]);
        }
    }

    function batchTransferWithLock(address[] calldata recipients, uint256[] calldata amounts) external onlyAdmin {
        require(recipients.length == amounts.length, "Mismatched arrays");
        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 lockAmount = (amounts[i] * lockPercentage) / 100;
            uint256 transferAmount = amounts[i] - lockAmount;

            // Send the directly available portion
            require(token.transfer(recipients[i], transferAmount), "Direct transfer failed");
            emit TransferPerformed(msg.sender, recipients[i], transferAmount);

            // Lock the specified portion
            if (lockedFunds[recipients[i]] == 0) {
                lockedRecipients.push(recipients[i]);
            }
            lockedFunds[recipients[i]] += lockAmount;
            emit FundsLocked(recipients[i], lockAmount);
        }
    }

    function claimLockedFunds() external {
        uint256 amount = lockedFunds[msg.sender];
        require(amount > 0, "No locked funds available");

        lockedFunds[msg.sender] = 0;
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(msg.sender, amount), "Claim transfer failed");
        emit FundsClaimed(msg.sender, amount);

        // Remove the recipient from the locked list
        _removeLockedRecipient(msg.sender);
    }

    function releaseAllLockedFunds() external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalAmount;

        for (uint256 i = 0; i < lockedRecipients.length; i++) {
            address user = lockedRecipients[i];
            uint256 lockedAmount = lockedFunds[user];

            if (lockedAmount > 0) {
                lockedFunds[user] = 0;
                require(token.transfer(user, lockedAmount), "Release transfer failed");
                emit FundsClaimed(user, lockedAmount);
                totalAmount += lockedAmount;
            }
        }

        // Clear the list of locked recipients
        delete lockedRecipients;

        emit AllLockedFundsReleased(address(this), totalAmount);
    }

    function getLockedFunds(address account) external view returns (uint256) {
        return lockedFunds[account];
    }

    // New function to get all locked recipients and their funds
    function getAllLockedFunds() external view returns (address[] memory, uint256[] memory) {
        uint256 length = lockedRecipients.length;
        address[] memory recipients = new address[](length);
        uint256[] memory amounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            recipients[i] = lockedRecipients[i];
            amounts[i] = lockedFunds[lockedRecipients[i]];
        }

        return (recipients, amounts);
    }

    // Internal function to remove a specific locked recipient
    function _removeLockedRecipient(address recipient) internal {
        uint256 length = lockedRecipients.length;
        for (uint256 i = 0; i < length; i++) {
            if (lockedRecipients[i] == recipient) {
                lockedRecipients[i] = lockedRecipients[length - 1];
                lockedRecipients.pop();
                break;
            }
        }
    }
}

