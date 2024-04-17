pragma solidity ^0.8.0;
contract ContractRegistry {
    struct CPContractInfo {
        address owner;
        address cpAccountContract;
    }

    mapping(address => CPContractInfo) public cpContracts;

    event CPContractRegistered(address indexed cpContract, address indexed owner);
    event CPAddressChanged(address indexed cp, address newCP);

    function registerCPContract(address cpContract, address owner) external {
        require(cpContract != address(0), "Invalid CP contract address");
        require(owner != address(0), "Invalid owner address");
        require(cpContracts[cpContract].cpAccountContract == address(0), "CP contract already registered");

        cpContracts[cpContract] = CPContractInfo({
            owner: owner,
            cpAccountContract: cpContract
        });

        emit CPContractRegistered(cpContract, owner);
    }

    function changeOwner(address cpContract, address newOwner) external {
        require(cpContracts[cpContract].owner == msg.sender, "Only owner can call this function");
        cpContracts[cpContract].owner = newOwner;

        emit CPAddressChanged(cpContract, newOwner);
    }
}
