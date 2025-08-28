### New node sync test

from request import post_request, get_request
import subprocess
import time
from setup import setup

setup()

processes = []
processes.append(subprocess.Popen(['python', 'src/node.py', '--name', 'advent', '--port', '5000']))
time.sleep(1)  # Wait 1 second to allow the node to start

print("\n--- POST FUWA --> MOCO TRANSACTION ---")
data = {
    "sender": "Fuwawa",
    "recipient": "Mococo",
    "amount": 44.44
}
post_request("http://localhost:5000/transaction", data)

print("\n--- POST NERISSA --> SHIORI TRANSACTION ---")
data = {
    "sender": "Nerizza",
    "recipient": "Novella",
    "amount": 69.69
}
post_request("http://localhost:5000/transaction", data)

print("\n--- POST NERISSA --> BIBOO TRANSACTION ---")
data = {
    "sender": "Nerizza",
    "recipient": "Biboo",
    "amount": 13.37
}
post_request("http://localhost:5000/transaction", data)

print("\n--- MINE AT ADVENT ---")
response = get_request("http://localhost:5000/mine")

print("\n--- STARTING NEW NODE JUSTICE TO SYNC THE CHAIN ---")
processes.append(subprocess.Popen(['python', 'src/node.py', '--name', 'justice', '--port', '5001']))
time.sleep(5)  # Wait 5 seconds to allow the new node to sync

# Stop the nodes
for process in processes:
    process.terminate()
    process.wait()