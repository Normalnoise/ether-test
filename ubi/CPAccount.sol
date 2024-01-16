// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CPAccount {
    address public owner;
    string public nodeId;
    string[] public multiAddresses;
    uint8 public ubiFlag;

    struct Beneficiary {
        address beneficiaryAddress;
        uint256 quota;
        uint256 expiration;
    }

    Beneficiary public beneficiary;

    struct Task {
        string taskId;
        uint8 taskType;
        string zkType;
        string proof;
        bool isSubmitted;
    }

    mapping(string => Task) public tasks;

    constructor(
        address _owner,
        string memory _nodeId,
        string[] memory _multiAddresses,
        uint8 _ubiFlag,
        address _beneficiaryAddress
    ) {
        owner = _owner;
        nodeId = _nodeId;
        multiAddresses = _multiAddresses;
        ubiFlag = _ubiFlag;
        beneficiary = Beneficiary({
                beneficiaryAddress: _beneficiaryAddress,
                quota: 0,
                expiration: 0
                });

    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function changeMultiaddrs(string[] memory newMultiaddrs) public onlyOwner {
        multiAddresses = newMultiaddrs;
    }

    function changeOwnerAddress(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function changeBeneficiary(
        address newBeneficiary,
        uint256 newQuota,
        uint256 newExpiration
    ) public onlyOwner {
        beneficiary = Beneficiary({
        beneficiaryAddress: newBeneficiary,
        quota: newQuota,
        expiration: newExpiration
        });
    }

        function changeUbiFlag(uint8 newUbiFlag) public onlyOwner {
            ubiFlag = newUbiFlag;
        }


    function submitUBIProof(string memory _taskId, uint8 _taskType, string memory _zkType, string memory _proof) public onlyOwner {
        require(!tasks[_taskId].isSubmitted, "Proof for this task is already submitted.");
        tasks[_taskId] = Task({
        taskId: _taskId,
        taskType: _taskType,
        zkType: _zkType,
        proof: _proof,
        isSubmitted: true
        });
    }
}