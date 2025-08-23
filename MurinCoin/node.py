from flask import Flask, request, jsonify
from blockchain import HoloChain, MurinBlock, GigiTransaction
from hashlib import sha256
import datetime
import json

class JusticePool:
    def __init__(self, path):
        self.path = path + "/pool.json"
        self.load_pool()
    
    def load_pool(self):
        try:
            with open(self.path, 'r') as f:
                self.pool = [GigiTransaction(**tx) for tx in json.load(f)]
        except FileNotFoundError:
            self.pool = []
            print(f"Pool file {self.path} not found. Starting with an empty pool.")
        except json.JSONDecodeError:
            print(f"Error decoding JSON from {self.path}. Starting with an empty pool.")
            self.pool = []
        except TypeError as e:
            print(f"Type error while loading pool: {e}. Starting with an empty pool.")
            self.pool = []
    
    def save_pool(self):
        with open(self.path, 'w') as f:
            json.dump([tx.__dict__ for tx in self.pool], f, indent=4)
    
    def append(self, transaction: GigiTransaction):
        if not isinstance(transaction, GigiTransaction):
            raise TypeError("transaction must be an instance of GigiTransaction")
        self.pool.append(transaction)
        self.save_pool()
        print(f"Transaction '{transaction}' added to the pool.")
    
    def clear(self):
        self.pool = []
        self.save_pool()
        print("Transaction pool cleared.")
        
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

# Synchronization via receiving blocks
@app.route('/block', methods=['POST'])
def add_block():
    values = request.get_json()

    # Check that the required fields of a block are in the POST'ed data
    required = ['index', 'timestamp', 'data', 'previous_hash', 'hash']
    if not all(k in values for k in required):
        return 'Missing values', 400

    # Create a new block
    block = MurinBlock(
        index=values['index'],
        timestamp=values['timestamp'],
        data=[GigiTransaction(**tx) for tx in values['data']],
        previous_hash=values['previous_hash'],
        hash=values['hash']
    )
    
    # Check previous hash and index
    # TODO: Finish this


@app.route('/mine', methods=['GET'])
def mine():
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
    
    def nonce_hash(prefix: str, difficulty: int = 4) -> tuple[int, str]:
        target = '0' * difficulty
        for n in range(2**32):
            test_str = f"{prefix}:{n}"
            hash_result = sha256(test_str.encode()).hexdigest()
            if hash_result.startswith(target):
                return n, hash_result
        raise ValueError("No valid nonce found")
    
    # def broadcast(block: MurinBlock, nonce: int):  
    
    # START OF MINING PROCESS
    if not pool:
        return 'No transactions to mine', 400
        
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
    
    # TODO: Broadcast the new block to other nodes in the network
    
    response = {
        'message': 'New block successfully mined',
        'block': str(block)
    }
    return jsonify(response), 200

if __name__ == '__main__':
    import os
    os.system('clear')
    
    name = input("Enter this node's name: ")
    os.mkdir(name) if not os.path.exists(name) else print(f"Directory {name} already exists! Using existing data.")
    
    pool = JusticePool(name)
    chain = HoloChain(name)
    
    app.run()
    