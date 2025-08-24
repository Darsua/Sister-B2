from request import post_request, get_request
import subprocess
import time
import os

# Remove existing files to start fresh (I'm sorry)
if os.path.exists("advent/chain.json"):
    os.remove("advent/chain.json")
if os.path.exists("myth/chain.json"):
    os.remove("myth/chain.json")
if os.path.exists("advent/pool.json"):
    os.remove("advent/pool.json")
if os.path.exists("myth/pool.json"):
    os.remove("myth/pool.json")
if os.path.exists("advent"):
    os.rmdir("advent")
if os.path.exists("myth"):
    os.rmdir("myth")


# Start both nodes concurrently
processes = [
    subprocess.Popen(['python', 'src/node.py', '--name', 'advent', '--port', '5000']),
    subprocess.Popen(['python', 'src/node.py', '--name', 'myth', '--port', '5001'])
]
time.sleep(1)

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

print("\n--- MINE AT MYTH AND BROADCAST TO ADVENT ---")
response = get_request("http://localhost:5001/mine")

# Stop the nodes
for process in processes:
    process.terminate()
    process.wait()