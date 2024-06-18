// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TaskRegistryUpgradeable is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct TaskContractInfo {
        address owner;
        address taskContract;
    }

    mapping(address => TaskContractInfo) public taskContracts;

    event TaskContractRegistered(address indexed taskContract, address indexed owner);
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init(msg.sender);
    }

    function registerTaskContract(address task, address owner) external {
        require(task != address(0), "Invalid task contract address");
        require(owner != address(0), "Invalid owner address");
        require(taskContracts[task].taskContract == address(0), "Task contract already registered");

        taskContracts[task] = TaskContractInfo({
            owner: owner,
            taskContract: task
        });

        emit TaskContractRegistered(task, owner);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
