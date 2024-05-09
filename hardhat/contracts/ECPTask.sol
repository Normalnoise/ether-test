// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract ECPTask is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    struct TaskInfo {
        string id;
        uint typ;
        uint cp_type;
        string input_param;
        string verify_param;
        string cp_contracts;
        string reward_tx;
        string proof_tx;
        string status;
        string deadline;
        uint slash;
    }

    mapping(string => TaskInfo) public taskInfo;
    mapping(address => bool) public isAdmin;

    event CreateTask(string id, uint typ, uint cpType, string inputParams, string verifyParams, string cpContracts, string rewardTx, string proofTx, string status, string deadline, uint slash);
    event UpdateTaskInfo(string id, string rewardTx, string proofTx, string status, uint slash);
   
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        isAdmin[msg.sender] = true;
    }

    // Modifier to check if the caller is the admin
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Only the admin can call this function.");
        _;
    }

    function createTask(
        string memory id, 
        uint typ, 
        uint cp_type, 
        string memory inputParam, 
        string memory verifyParam, 
        string memory cpContracts, 
        string memory rewardTx, 
        string memory proofTx,
        string memory status,
        string memory deadline,
        uint slash
    ) public onlyAdmin {
        taskInfo[id] = TaskInfo(id, typ, cp_type, inputParam, verifyParam, cpContracts, rewardTx, proofTx, status, deadline, slash);
        emit CreateTask(id, typ, cp_type, inputParam, verifyParam, cpContracts, rewardTx, proofTx, status, deadline, slash);
    }

    function updateTaskInfo(
        string memory id,
        string memory rewardTx, 
        string memory proofTx,
        string memory status,
        uint slash
    ) public onlyAdmin {
        TaskInfo storage task = taskInfo[id];
        task.reward_tx = rewardTx;
        task.proof_tx = proofTx;
        task.status = status;
        task.slash = slash;
        emit UpdateTaskInfo(id, rewardTx, proofTx, status, slash);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function version() public pure returns(uint) {
        return 1;
    }

}