import os
import json
from web3 import Web3

web3 = Web3(Web3.HTTPProvider("https://saturn-rpc.swanchain.io"))


## load ABI JSON
def load_abi_from_json(file_path):
    with open(file_path, "r") as file:
        abi = json.load(file)
    return abi


## set up contract instance
def load_contract_instance(cp_account_address):
    dir = os.getcwd()
    abi_file_path = os.path.join(dir, "ubi/CPAccount.json")
    contract_abi = load_abi_from_json(abi_file_path)

    cp_account_contract = web3.eth.contract(
        address=cp_account_address, abi=contract_abi
    )
    return cp_account_contract


def get_events_between_blocks(cp_account_address, event_name, from_block, to_block):
    cp_account_contract = load_contract_instance(cp_account_address)

    # Filter events based on the specified block range
    event_filter = cp_account_contract.events[event_name].create_filter(
        fromBlock=from_block,
        toBlock=to_block,
    )

    # Get events within the block range
    events = event_filter.get_all_entries()

    return events


print(
    get_events_between_blocks(
        "0x357715b93c8Ce5124c2551F368BFFB34A0B6D273",
        "UBIProofSubmitted",
        0,
        web3.eth.get_block("latest").number,
    )
)
