import json

class GigiTransaction:
    def __init__(self, sender: str, recipient: str, amount: float):
        self.sender = sender
        self.recipient = recipient
        self.amount = amount

    def __repr__(self):
        return f"GigiTransaction(sender={self.sender}, recipient={self.recipient}, amount={self.amount})"
        
    def __str__(self):
        return f"{self.sender} sent {self.recipient} {self.amount} MurinCoins"

class MurinBlock:
    def __init__(self, index: int, timestamp: str, data: list[GigiTransaction], previous_hash: str, hash: str):
        self.index = index
        self.data = data
        self.previous_hash = previous_hash
        self.timestamp = timestamp
        self.hash = hash
        
    def __repr__(self):
        return (f"MurinBlock(index={self.index}, "
                f"timestamp={self.timestamp}, "
                f"transactions={self.data}, "
                f"previous_hash={self.previous_hash}, "
                f"hash={self.hash})")
        
    def __str__(self):
        return (f"MurinBlock {self.index}:\n"
                f"  Timestamp: {self.timestamp}\n"
                f"  Transactions:\n"
                f"    " + "\n    ".join(str(tx) for tx in self.data) + "\n"
                f"  Previous Hash: {self.previous_hash}\n"
                f"  Hash: {self.hash}")

def gremlinEncoder(obj):
    if isinstance(obj, GigiTransaction):
        return {
            "sender": obj.sender,
            "recipient": obj.recipient,
            "amount": obj.amount
        }
    elif isinstance(obj, MurinBlock):
        return {
            "index": obj.index,
            "timestamp": obj.timestamp,
            "data": [gremlinEncoder(tx) for tx in obj.data],
            "previous_hash": obj.previous_hash,
            "hash": obj.hash
        }
    raise TypeError(f"Object of type {obj.__class__.__name__} is not JSON serializable")

class HoloChain:
    def __init__(self, path):
        self.path = path + "/chain.json"
        self.chain = self.load_chain()
    
    def load_chain(self):
        try:
            with open(self.path, 'r') as f:
                chain = json.load(f)
                for i, block in enumerate(chain):
                    # Convert each block's transactions back to GigiTransaction objects
                    if 'data' in block:
                        block['data'] = [GigiTransaction(**tx) for tx in block['data']]
                    # Convert each block back to MurinBlock objects
                    chain[i] = MurinBlock(**block)
                return chain
        except FileNotFoundError:
            print(f"Chain file {self.path} not found. Starting an empty chain.")
            return []
        except json.JSONDecodeError:
            print(f"Error decoding JSON from {self.path}. Starting an empty chain.")
            return []
            
    def save_chain(self):
        try:
            with open(self.path, 'w') as f:
                json.dump(self.chain, f, default=gremlinEncoder, indent=2)
            print(f"Chain saved to {self.path}.")
        except IOError as e:
            print(f"Error saving chain to {self.path}: {e}")
            
    def add_block(self, block: MurinBlock):
        if not isinstance(block, MurinBlock):
            raise TypeError("block must be an instance of MurinBlock")
        if self.chain and block.index != self.chain[-1].index + 1:
            raise ValueError("Block index is not sequential")
        if self.chain and block.previous_hash != self.chain[-1].hash:
            raise ValueError("Block previous hash does not match the last block's hash")
        
        self.chain.append(block)
        print(f"Block {block.index} added to the chain.")
            
    def get_length(self):
        return len(self.chain)
    
    def get_last_hash(self):
        return self.chain[-1].hash if self.chain else ""
        
    def __repr__(self):
        return f"JusticeChain(length={self.get_length()})"
        
    def __str__(self):
        return "\n".join(str(block) for block in self.chain)