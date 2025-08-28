### Longer chain resync test

from request import post_request, get_request
import subprocess
import time
from setup import setup
import shutil
import os

setup()

processes = []
processes.append(subprocess.Popen(['python', 'src/node.py', '--name', 'advent', '--port', '5000']))
time.sleep(1)  # Wait 1 second to allow the node to start

# Add one block
print("\n--- POST FUWA --> MOCO TRANSACTION ---")
data = {
    "sender": "Fuwawa",
    "recipient": "Mococo",
    "amount": 44.44
}
post_request("http://localhost:5000/transaction", data)
print("\n--- MINE AT ADVENT ---")
response = get_request("http://localhost:5000/mine")

# Copy the short chain to justice node to simulate it being out of sync
os.mkdir('justice')
shutil.copy('advent/chain.json', 'justice/chain.json')

# Add another block to advent
print("\n--- POST NERISSA --> SHIORI TRANSACTION ---")
data = {
    "sender": "Nerizza",
    "recipient": "Novella",
    "amount": 69.69
}
post_request("http://localhost:5000/transaction", data)
print("\n--- MINE AT ADVENT ---")
response = get_request("http://localhost:5000/mine")

# Start justice node which has an out-of-date chain (using --no-sync flag)
print("\n--- STARTING NEW NODE JUSTICE TO SYNC THE CHAIN ---")
processes.append(subprocess.Popen(['python', 'src/node.py', '--name', 'justice', '--port', '5001', '--no-sync']))
time.sleep(1)  # Wait 1 second to start the node

# Add the third block to advent which will be broadcast to justice
print("\n--- POST NERISSA --> BIBOO TRANSACTION ---")
data = {
    "sender": "Nerizza",
    "recipient": "Biboo",
    "amount": 13.37
}
post_request("http://localhost:5000/transaction", data)
print("\n--- MINE AT ADVENT ---")
response = get_request("http://localhost:5000/mine")

# Stop the nodes
for process in processes:
    process.terminate()
    process.wait()