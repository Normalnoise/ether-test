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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MultiaddrsChanged(string[] newMultiaddrs);
    event BeneficiaryChanged(address beneficiary, uint quota, uint expiration);
    event UBIFlagChanged(uint8 ubiFlag);
    event UBIProofSubmitted(address indexed submitter, string taskId, uint8 taskType, string zkType, string proof);

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
    function getOwner() public view returns (address) {
        return owner;
    }
    function getAccount() public view returns (address, string memory, string[] memory, uint8, address, uint256, uint256) {
        return (owner, nodeId, multiAddresses, ubiFlag, beneficiary.beneficiaryAddress, beneficiary.quota, beneficiary.expiration);
    }
    function changeMultiaddrs(string[] memory newMultiaddrs) public onlyOwner {
        multiAddresses = newMultiaddrs;

        emit MultiaddrsChanged(newMultiaddrs);
    }
    function changeOwnerAddress(address newOwner) public onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
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

        emit BeneficiaryChanged(newBeneficiary, newQuota, newExpiration);
    }

    function changeUbiFlag(uint8 newUbiFlag) public onlyOwner {
        ubiFlag = newUbiFlag;
        emit UBIFlagChanged(newUbiFlag);
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

        emit UBIProofSubmitted(msg.sender, _taskId, _taskType, _zkType, _proof);
    }
}