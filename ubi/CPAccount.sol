// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract CPAccount {
    address public contractRegistryAddress;
    address public owner;
    address public worker;
    string public nodeId;
    string[] public multiAddresses;
    address public beneficiary;
    uint8[] public taskTypes; // New property

    struct Task {
        string taskId;
        uint8 type; // Changed to 'type'
        string proof;
        bool isSubmitted;
    }

    mapping(string => Task) public tasks;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WorkerChanged(address indexed previousWorker, address indexed newWorker);
    event MultiaddrsChanged(string[] newMultiaddrs);
    event BeneficiaryChanged(address previousBeneficiary, address newBeneficiary);
    event TaskTypesChanged(uint8[] newTaskTypes); // New event
    event UBIProofSubmitted(address indexed submitter, string taskId, uint8 type, string proof); // Changed to 'type'

    // Event to notify ContractRegistry when CPAccount is deployed
    event CPAccountDeployed(address indexed cpAccount, address indexed owner);

    constructor(
        string memory _nodeId,
        string[] memory _multiAddresses,
        address _beneficiary,
        address _worker,
        address _contractRegistryAddress,
        uint8[] memory _taskTypes // New parameter
    ) {
        owner = msg.sender;
        nodeId = _nodeId;
        multiAddresses = _multiAddresses;
        beneficiary = _beneficiary;
        worker = _worker;
        contractRegistryAddress = _contractRegistryAddress;
        taskTypes = _taskTypes; // Initialize taskTypes

        // Register CPAccount to ContractRegistry
        registerToContractRegistry();

        // Emit event to notify CPAccount deployment
        emit CPAccountDeployed(address(this), owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function registerToContractRegistry() private {
        // Call registerCPContract function of ContractRegistry
        (bool success, ) = contractRegistryAddress.call(abi.encodeWithSignature("registerCPContract(address,address)", address(this), owner));
        require(success, "Failed to register CPContract to ContractRegistry");
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getWorker() public view returns (address) {
        return worker;
    }

    function getBeneficiary() public view returns (address) {
        return beneficiary;
    }

    function getMultiAddresses() public view returns (string[] memory) {
        return multiAddresses;
    }

    function getTaskTypes() public view returns (uint8[] memory) {
        return taskTypes;
    }

    function changeTaskTypes(uint8[] memory newTaskTypes) public onlyOwner {
        taskTypes = newTaskTypes;

        emit TaskTypesChanged(newTaskTypes);
    }

    function changeMultiaddrs(string[] memory newMultiaddrs) public onlyOwner {
        multiAddresses = newMultiaddrs;

        emit MultiaddrsChanged(newMultiaddrs);
    }

    function changeOwnerAddress(address newOwner) public onlyOwner {
        owner = newOwner;

        // Emit event to notify ContractRegistry about owner change
        emit OwnershipTransferred(msg.sender, newOwner);

        // Call changeOwner function of ContractRegistry to update owner
        (bool success, ) = contractRegistryAddress.call(abi.encodeWithSignature("changeOwner(address,address)", address(this), newOwner));
        require(success, "Failed to change owner in ContractRegistry");
    }

    function changeBeneficiary(address newBeneficiary) public onlyOwner {
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
    }

    function changeWorker(address newWorker) public onlyOwner {
        worker = newWorker;
        emit WorkerChanged(worker, newWorker);
    }

    function submitUBIProof(string memory _taskId, uint8 _type, string memory _proof) public onlyOwner {
        require(!tasks[_taskId].isSubmitted, "Proof for this task is already submitted.");
        tasks[_taskId] = Task({
            taskId: _taskId,
            type: _type,
            proof: _proof,
            isSubmitted: true
        });

        emit UBIProofSubmitted(msg.sender, _taskId, _type, _proof);
    }
}
