from web3 import Web3
import json

# 连接到以太坊节点
w3 = Web3(Web3.HTTPProvider('https://saturn-rpc.swanchain.io'))

# 合约地址
contract_address = "0x734c4309359ba3cbd5014f853bb4cfef0c6d1aaa"
contract_address = Web3.to_checksum_address(contract_address)
# 从本地文件加载合约 ABI
with open('contractRegistry.json', 'r') as file:
    contract_abi = json.load(file)

# 加载合约
contract = w3.eth.contract(address=contract_address, abi=contract_abi)
step_block = 2

# 扫描已注册的 CP 合约信息
def scan_cp_contracts(start_block, end_block, event_name):
    current_block = w3.eth.block_number
    end_block = min(end_block, current_block)
    for block_number in range(start_block, end_block, step_block):
        print(block_number)
        event_filter = contract.events[event_name].create_filter(
         fromBlock=block_number,
         toBlock=block_number + step_block - 1,
         )
        events = event_filter.get_all_entries()

        for event in events:
            print("blockNumber:", event["blockNumber"])
            print("cpContract:", event['args']['cpContract'])
            print("owner:", event['args']['owner'])


if __name__ == "__main__":
    # 扫描区块的起始和结束高度
    start_block_height = 5379460
    end_block_height = 5379470  # 你想要扫描的结束区块高度

    # 扫描
    scan_cp_contracts(start_block_height, end_block_height,"CPContractRegistered" )
