### Transaction upload, mining, and block synchronization test script

from request import post_request, get_request
import subprocess
import time
from setup import setup

setup()

processes = []
node_configs = [
    ('advent', '5000'),
    ('council', '5001'),
    ('justice', '5002'),
    ('myth', '5003')
]

for name, port in node_configs:
    processes.append(subprocess.Popen(['python', 'src/node.py', '--name', name, '--port', port]))
    time.sleep(1)  # Wait 1 second before starting the next node

print("\n--- POST GIGI --> CC TRANSACTION ---")
data = {
    "sender": "Gigi Murin",
    "recipient": "CC",
    "amount": 69.69
}
post_request("http://localhost:5001/transaction", data)

print("\n--- POST LIZ --> RAORA TRANSACTION ---")
data = {
    "sender": "Liz",
    "recipient": "Raora",
    "amount": 13.37
}
post_request("http://localhost:5001/transaction", data)

print("\n--- MINE AT COUNCIL AND BROADCAST TO OTHERS ---")
response = get_request("http://localhost:5001/mine")

# Stop the nodes
for process in processes:
    process.terminate()
    process.wait()