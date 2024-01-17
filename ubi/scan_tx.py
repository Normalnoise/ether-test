import os
import json

from web3 import Web3

# Initialize a web3 instance
web3 = Web3(Web3.HTTPProvider("https://saturn-rpc.swanchain.io"))


## load ABI JSON
def load_abi_from_json(file_path):
    with open(file_path, "r") as file:
        abi = json.load(file)
    return abi


## set up contract instance, since we just scanning event, we dont need a contract address, just abi is enough
def load_contract_instance():
    dir = os.getcwd()
    abi_file_path = os.path.join(dir, "ubi/CPAccount.json")
    contract_abi = load_abi_from_json(abi_file_path)

    cp_account_contract = web3.eth.contract(abi=contract_abi)
    return cp_account_contract


def scan_tx(tx_hash):
    cp_account_contract = load_contract_instance()
    transaction_receipt = web3.eth.get_transaction_receipt(
        tx_hash
    )  ## get the tx receipt

    for log in transaction_receipt["logs"]:
        ## scan the tx event, can scan different events, just change the eventName
        event = cp_account_contract.events.UBIProofSubmitted().process_log(log)
        print("Decoded Event:", event)


scan_tx("0x599b0895387c6cb48ead0658a468ac50d5719c0f15c012cfda28ee5f555909a8")
