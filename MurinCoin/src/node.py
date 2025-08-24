from flask import Flask, request, jsonify
from blockchain import HoloChain, MurinBlock, GigiTransaction
from hashlib import sha256
import datetime
import json
import requests

class JusticePool:
    def __init__(self, name):
        self.name = name
        self.load_pool()

    def load_pool(self):
        try:
            with open(self.name + "/pool.json", 'r') as f:
                self.pool = [GigiTransaction(**tx) for tx in json.load(f)]
        except FileNotFoundError:
            self.pool = []
            print(f"[{self.name}] Pool file not found. Starting with an empty pool.")
        except json.JSONDecodeError:
            print(f"[{self.name}] Pool file is corrupted or empty. Starting with an empty pool.")
            self.pool = []
        except TypeError as e:
            print(f"[{self.name}] Error loading pool: {e}. Starting with an empty pool.")
            self.pool = []

    def save_pool(self):
        with open(self.name + "/pool.json", 'w') as f:
            json.dump([tx.__dict__ for tx in self.pool], f, indent=4)

    def append(self, transaction: GigiTransaction):
        if not isinstance(transaction, GigiTransaction):
            raise TypeError("transaction must be an instance of GigiTransaction")
        self.pool.append(transaction)
        self.save_pool()
        print(f"[{self.name}] Transaction '{transaction}' added to the pool.")

    def clear(self):
        self.pool = []
        self.save_pool()
        print(f"[{self.name}] Transaction pool cleared.")

    def get_pool(self):
        return self.pool

app = Flask(__name__)

# Adding a transaction to the pool
@app.route('/transaction', methods=['POST'])
def add_transaction():
    values = request.get_json()

    # Check that the required fields of a transcation are in the POST'ed data
    required = ['sender', 'recipient', 'amount']
    if not all(k in values for k in required):
        return 'Missing values', 400

    # Create a new transaction
    transaction = GigiTransaction(
        sender=values['sender'],
        recipient=values['recipient'],
        amount=values['amount']
    )
    pool.append(transaction) # Add the transaction to the pool

    # Create a response
    response = {
        'message': 'Transaction will be added to the next block',
        'transaction': str(transaction)
    }
    return jsonify(response), 201

# Based on https://youtu.be/fB41w3JcR7U
def merkle_root(transactions: list[GigiTransaction]) -> str:
    root = [sha256(str(t).encode()).hexdigest() for t in transactions]
    while len(root) > 1:
        new_root = []
        for i in range(0, len(root), 2):
            if i + 1 < len(root):
                new_root.append(sha256((root[i] + root[i + 1]).encode()).hexdigest())
            else:
                new_root.append(sha256((root[i] + root[i]).encode()).hexdigest())
        root = new_root
    return root[0] if root else ''

# Synchronization via receiving blocks
@app.route('/block', methods=['POST'])
def add_block():
    values = request.get_json()

    # Check that the required fields of a block are in the POST'ed data
    required = ['block', 'nonce']
    if not all(k in values for k in required):
        return 'Missing values', 400

    try:
        block = MurinBlock.unpack(values['block'])
        nonce = int(values['nonce'])
    except (ValueError, TypeError) as e:
        return f"Invalid block or nonce: {e}", 400
    
    print(f"[{pool.name}] Received block {block.index} for validation.")
    ### BLOCK VALIDATION ###
    # Check the index
    if block.index < chain.get_length():
        return 'Block is part of a chain with a shorter or equivalent length', 400
    elif block.index > chain.get_length():
        # TODO: Perform GET /chain to the whole network to get the latest chain
        return 'Block is part of a chain with a longer length', 400
    # else block is the next block in the chain
    
    # Check the previous hash
    if block.previous_hash != chain.get_last_hash():
        return 'Invalid previous hash', 400
        
    # Check hash and PoW
    prefix = f"{block.index}{block.timestamp}{merkle_root(block.data)}{block.previous_hash}"
    hash = sha256((prefix + ":" + str(nonce)).encode()).hexdigest()
    if hash != block.hash:
        return f'Invalid hash or nonce\n{hash}\nvs.\n{block.hash}', 400
        
    # Block is valid
    try:
        chain.add_block(block)
        chain.save_chain()  # Save the chain to a file
    except (TypeError, ValueError) as e:
        return str(e), 400
        
    response = {
        'message': 'New block has been added to the chain',
        'block': str(block)
    }
    return jsonify(response), 201
    

@app.route('/mine', methods=['GET'])
def mine():
    def nonce_hash(prefix: str, difficulty: int = 4) -> tuple[int, str]:
        target = '0' * difficulty
        for n in range(2**32):
            test_str = f"{prefix}:{n}"
            hash_result = sha256(test_str.encode()).hexdigest()
            if hash_result.startswith(target):
                return n, hash_result
        raise ValueError("No valid nonce found")

    def broadcast(block: MurinBlock, nonce: int, src: str = ""):
        addresses = ['http://localhost:5000']  # TODO: PEER DISCOVERY
        for address in addresses:
            try:
                print(f"[{src}] Broadcasting block {block.index} to {address}...")
                response = requests.post(f"{address}/block", json={
                    'block': block.pack(),
                    'nonce': nonce
                })
                if response.status_code != 201:
                    print(f"[{src}] Failed to broadcast block to {address}: {response.text}")
            except requests.exceptions.RequestException as e:
                print(f"[{src}] Error broadcasting block to {address}: {e}")

    # START OF MINING PROCESS
    if not pool:
        return 'No transactions to mine', 400
        
    print(f"[{pool.name}] Mining for block {chain.get_length()}.")
    root = merkle_root(pool.get_pool())
    timestamp = datetime.datetime.now().isoformat()
    nonce, hash = nonce_hash(str(chain.get_length()) + timestamp + root + chain.get_last_hash())

    block = MurinBlock(
        index=chain.get_length(),
        timestamp=timestamp,
        data=pool.get_pool().copy(),
        previous_hash=chain.get_last_hash(),
        hash=hash
    )

    # Add the block to the chain
    try:
        chain.add_block(block)
        chain.save_chain()  # Save the chain to a file
    except (TypeError, ValueError) as e:
        return str(e), 400

    # Clear the pool after mining
    pool.clear()

    # Broadcast the new block to other nodes
    broadcast(block, nonce, pool.name)

    response = {
        'message': 'New block successfully mined',
        'block': str(block)
    }
    return jsonify(response), 200

if __name__ == '__main__':
    import os
    import argparse
    
    parser = argparse.ArgumentParser(description='MurinCoin Node')
    parser.add_argument('--name', type=str, help='Name of the node directory', required=True)
    parser.add_argument('--port', type=int, default=5000, help='Port to run the node on')
    args = parser.parse_args()
    
    os.system('clear')
    os.mkdir(args.name) if not os.path.exists(args.name) else print(f"[{args.name}] Directory already exists! Using existing data.")

    pool = JusticePool(args.name)
    chain = HoloChain(args.name)
    
    app.run(port=args.port)
