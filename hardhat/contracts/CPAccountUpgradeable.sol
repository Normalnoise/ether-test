// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract CPAccountUpgradeable is Initializable, UUPSUpgradeable {
    address public contractRegistryAddress;
    address public owner;
    address public worker;
    string public nodeId;
    string[] public multiAddresses;
    address public beneficiary;
    uint8[] public taskTypes;
    string public VERSION; // Contract version

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event WorkerChanged(address indexed previousWorker, address indexed newWorker);
    event MultiaddrsChanged(string[] previousMultiaddrs, string[] newMultiaddrs);
    event BeneficiaryChanged(address indexed previousBeneficiary, address indexed newBeneficiary);
    event TaskTypesChanged(uint8[] previousTaskTypes, uint8[] newTaskTypes); 
    
    // Event to notify ContractRegistry when CPAccount is deployed
    event CPAccountDeployed(address indexed cpAccount, address indexed owner);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        string memory _nodeId,
        string[] memory _multiAddresses,
        address _beneficiary,
        address _worker,
        address _contractRegistryAddress,
        uint8[] memory _taskTypes
    ) initializer public {
        __UUPSUpgradeable_init();

        owner = msg.sender;
        nodeId = _nodeId;
        multiAddresses = _multiAddresses;
        beneficiary = _beneficiary;
        worker = _worker;
        contractRegistryAddress = _contractRegistryAddress;
        taskTypes = _taskTypes; // Initialize taskTypes
        VERSION = '2.0';

        // Register CPAccount to ContractRegistry
        registerToContractRegistry();

        // Emit event to notify CPAccount deployment
        emit CPAccountDeployed(address(this), owner);
    }

   modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier ownerAndWorker() {
        require(msg.sender == owner|| msg.sender == worker, "owner and worker can call this function.");
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
    function getVersion() public view returns (string memory) {
        return VERSION;
    }

    function changeTaskTypes(uint8[] memory newTaskTypes) public onlyOwner {
        emit TaskTypesChanged(taskTypes, newTaskTypes);
        taskTypes = newTaskTypes;
    }

    function changeMultiaddrs(string[] memory newMultiaddrs) public onlyOwner {
        emit MultiaddrsChanged(multiAddresses, newMultiaddrs);
        multiAddresses = newMultiaddrs;
    }

    function changeOwnerAddress(address newOwner) public onlyOwner {

        // Call changeOwner function of ContractRegistry to update owner
        // (bool success, ) = contractRegistryAddress.call(abi.encodeWithSignature("changeOwner(address,address)", address(this), newOwner));
        // require(success, "Failed to change owner in ContractRegistry");


        // 调用 ContractRegistry 的 changeOwner 函数以更新所有者
        (bool success, bytes memory data) = contractRegistryAddress.call(
            abi.encodeWithSignature("changeOwner(address,address)", address(this), newOwner)
        );

        if (!success) {
            // 尝试将返回的数据解码为字符串
            if (data.length > 0) {
                string memory errorMessage = _getRevertMsg(data);
                revert(errorMessage);
            } else {
                revert("Failed to change owner in ContractRegistry");
            }
        }

        owner = newOwner;

        // Emit event to notify ContractRegistry about owner change
        emit OwnershipTransferred(msg.sender, newOwner);
    }
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68) return "Transaction reverted silently";
        
        assembly {
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
    }

    function changeBeneficiary(address newBeneficiary) public onlyOwner {
        beneficiary = newBeneficiary;
        emit BeneficiaryChanged(beneficiary, newBeneficiary);
    }

    function changeWorker(address newWorker) public onlyOwner {
        worker = newWorker;
        emit WorkerChanged(worker, newWorker);
    }

    struct CpInfo {
        address owner;
        string nodeId;
        string[] multiAddresses;
        address beneficiary;
        address worker;
        uint8[] taskTypes;
        string version;
    }

    function getAccount() public view returns (CpInfo memory) {
        return CpInfo(owner,nodeId, multiAddresses, beneficiary, worker, taskTypes, VERSION);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
