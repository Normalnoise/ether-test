// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ECPTask {
    // Task properties
    uint256 public taskID;
    string public taskType;
    string public resourceType;
    string public inputParam;
    string public verifyParam;
    address public cpAccount;
    string public proof;
    uint256 public deadline;
    address public taskRegistryContract;
    string public checkCode;

    // Contract owner
    address public owner;

    // Event to log registration
    event RegisteredToTaskRegistry(address indexed taskContract, address indexed owner);

    // Constructor to initialize the task properties and register the task contract
    constructor(
        uint256 _taskID,
        string memory _taskType,
        string memory _resourceType,
        string memory _inputParam,
        string memory _verifyParam,
        address _cpAccount,
        string memory _proof,
        uint256 _deadline,
        address _taskRegistryContract,
        string memory _checkCode
    ) {
        taskID = _taskID;
        taskType = _taskType;
        resourceType = _resourceType;
        inputParam = _inputParam;
        verifyParam = _verifyParam;
        cpAccount = _cpAccount;
        proof = _proof;
        deadline = _deadline;
        taskRegistryContract = _taskRegistryContract;
        checkCode = _checkCode;
        owner = msg.sender;

        // Register this task contract with the TaskRegistry
        registerToTaskRegistry();
    }

    // Private function to register this contract with the TaskRegistry
    function registerToTaskRegistry() private {
        (bool success, ) = taskRegistryContract.call(
            abi.encodeWithSignature(
                "registerTaskContract(address,address)",
                address(this),
                owner
            )
        );
        require(success, "Failed to register task contract to TaskRegistry");
        
        // Emit the event after successful registration
        emit RegisteredToTaskRegistry(address(this), owner);
    }

}
