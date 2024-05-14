// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract ECPTask is Ownable {

    struct TaskInfo {
        uint taskType;
        uint resourceType;
        string inputParam;
        string verifyParam;
        address cpContractAddress;
        string status;
        string rewardTx;
        string proof;
        string challengeTx;
        string lockFundTx;
        string unLockFundTx;
        string slashTx;
        uint deadline;
        bool isSubmitted;
        bool isChallenged;
    }

    TaskInfo public taskInfo;
    mapping(address => bool) public isAdmin;

    event RewardAndStatusUpdated(string rewardTx, string status);
    event LockAndStatusUpdated(string lockFundTx, string status);
    event UnlockAndStatusUpdated(string unLockFundTx, string status);
    event ChallengeAndStatusUpdated(string challengeTx, string status);
    event SlashAndStatusUpdated(string slashTx, string status);

    event SubmitProof(string proof);

    constructor(
        uint _taskType,
        uint _resourceType,
        string memory _inputParam,
        string memory _verifyParam,
        address _cpContractAddress,
        string memory _status,
        string memory _lockFundTx,
        uint _deadline
    ) Ownable(msg.sender) {
        taskInfo = TaskInfo({
            taskType: _taskType,
            resourceType: _resourceType,
            inputParam: _inputParam,
            verifyParam: _verifyParam,
            cpContractAddress: _cpContractAddress,
            status: _status,
            rewardTx: "",
            proof: "",
            challengeTx: "",
            lockFundTx: _lockFundTx,
            unLockFundTx: "",
            slashTx: "",
            deadline: _deadline,
            isSubmitted: false,
            isChallenged: false
        });
        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function updateRewardAndStatus(
        string memory rewardTx,
        string memory status
    ) public onlyAdmin {
        taskInfo.rewardTx = rewardTx;
        taskInfo.status = status;
        emit RewardAndStatusUpdated(rewardTx, status);
    }

    function updateLockAndStatus(
        string memory lockFundTx,
        string memory status
    ) public onlyAdmin {
        taskInfo.lockFundTx = lockFundTx;
        taskInfo.status = status;
        emit LockAndStatusUpdated(lockFundTx, status);
    }

    function updateUnlockAndStatus(
        string memory unlockFundTx,
        string memory status
    ) public onlyAdmin {
        taskInfo.unLockFundTx = unlockFundTx;
        taskInfo.status = status;
        emit UnlockAndStatusUpdated(unlockFundTx, status);
    }

    function updateChallengeAndStatus(
        string memory challengeTx,
        string memory status
    ) public onlyAdmin {
        taskInfo.challengeTx = challengeTx;
        taskInfo.status = status;
        taskInfo.isChallenged = true;
        emit ChallengeAndStatusUpdated(challengeTx, status);
    }

    function updateSlashAndStatus(
        string memory slashTx,
        string memory status
    ) public onlyAdmin {
        taskInfo.slashTx = slashTx;
        taskInfo.status = status;
        emit SlashAndStatusUpdated(slashTx, status);
    }

    function submitProof(string memory proof) public {
        (bool successWorker, bytes memory CPOwner) = taskInfo.cpContractAddress.call(abi.encodeWithSignature("getOwner()"));
        require(successOwner, "Failed to call getOwner function of CPAccount");
        address owner = abi.decode(CPOwner, (address));

        (bool successWorker, bytes memory CPWorker) = taskInfo.cpContractAddress.call(abi.encodeWithSignature("getWorker()"));
        require(successWorker, "Failed to call getWorker function of CPAccount");
        address worker = abi.decode(CPWorker, (address));

        require(msg.sender == owner || msg.sender == worker, "Only the CP contract owner or worker can submit proof.");

        taskInfo.proof = proof;
        taskInfo.isSubmitted = true;
        emit SubmitProof(proof);
    }

    function getTaskInfo() public view returns(TaskInfo memory) {
        return taskInfo;
    }

    function version() public pure returns(string memory) {
        return "1.0.0";
    }
}
