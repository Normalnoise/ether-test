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

    event TransferPerformed(address indexed from, address indexed cpAccount, address cpBeneficiary, uint256 amount, string cpType);
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);
    event TokenAddressUpdated(address indexed oldTokenAddress, address indexed newTokenAddress);
    event LockPercentageUpdated(uint256 oldLockPercentage, uint256 newLockPercentage);
    event FundsLocked(address indexed recipient, uint256 amount, uint256 totalLockAmount);
    event FundsReleased(address indexed cpAccount, address cpBeneficiary, uint256 lockedAmount);
    event AllLockedFundsReleased(address indexed contractAddress, uint256 totalAmount);
    event TokensWithdrawn(address indexed tokenAddress, uint256 amount, address indexed to);
    event ETHWithdrawn(uint256 amount, address indexed to);

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

    function batchTransfer(address[] calldata cps, uint256[] calldata amounts, string memory cpType) external onlyAdmin {
        require(cps.length == amounts.length, "Mismatched arrays");
        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < cps.length; i++) {
            address cpBeneficiary = _getBeneficiary(cps[i]);
            require(token.transfer(cpBeneficiary, amounts[i]), "Transfer failed");
            emit TransferPerformed(msg.sender, cps[i], cpBeneficiary, amounts[i], cpType);
        }
    }

    function batchTransferWithLock(address[] calldata cps, uint256[] calldata amounts) external onlyAdmin {
        require(cps.length == amounts.length, "Mismatched arrays");
        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < cps.length; i++) {
            uint256 lockAmount = (amounts[i] * lockPercentage) / 100;
            uint256 transferAmount = amounts[i] - lockAmount;

            address cpBeneficiary = _getBeneficiary(cps[i]);

            // Send the directly available portion
            require(token.transfer(cpBeneficiary, transferAmount), "Direct transfer failed");
            emit TransferPerformed(msg.sender, cps[i], cpBeneficiary, transferAmount);

            // Lock the specified portion
            if (lockedFunds[cps[i]] == 0) {
                lockedRecipients.push(cps[i]);
            }
            lockedFunds[cps[i]] += lockAmount;
            emit FundsLocked(cps[i], lockAmount, lockedFunds[cps[i]]);
        }
    }

    function releaseAllLockedFunds() external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 totalAmount;

        for (uint256 i = lockedRecipients.length; i > 0; i--) {
            address cp = lockedRecipients[i - 1];
            uint256 lockedAmount = lockedFunds[cp];

            if (lockedAmount > 0) {
                address cpBeneficiary = _getBeneficiary(cp);
                lockedFunds[cp] = 0;
                require(token.transfer(cpBeneficiary, lockedAmount), "Release transfer failed");
                emit FundsReleased(cp, cpBeneficiary, lockedAmount);
                totalAmount += lockedAmount;

                // Remove locked recipient after releasing funds
                _removeLockedRecipient(cp);
            }
        }

        emit AllLockedFundsReleased(address(this), totalAmount);
    }

    function getLockedFunds(address cp) external view returns (uint256) {
        return lockedFunds[cp];
    }

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

    // Allows the owner to withdraw ERC20 tokens from the contract
    function withdrawTokens(uint256 amount) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(owner, amount), "Token withdrawal failed");
        emit TokensWithdrawn(tokenAddress, amount, owner);
    }

    // Allows the owner to withdraw ETH from the contract
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        payable(owner).transfer(amount);
        emit ETHWithdrawn(amount, owner);
    }

    // Internal function to get beneficiary address from cpAccount
    function _getBeneficiary(address cpAccount) internal returns (address) {
        (bool success, bytes memory CPBeneficiary) = cpAccount.call(abi.encodeWithSignature("getBeneficiary()"));
        require(success, "Failed to call getBeneficiary function of CPAccount");
        return abi.decode(CPBeneficiary, (address));
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

    // Fallback function to receive ETH
    receive() external payable {}
}
