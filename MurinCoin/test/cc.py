import subprocess
import time
import os

os.system('clear')

# Remove existing files (I'm sorry again)
for dirname in ["advent", "myth", "council", "justice"]:
    if os.path.exists(f"{dirname}/chain.json"):
        os.remove(f"{dirname}/chain.json")
    if os.path.exists(f"{dirname}/pool.json"):
        os.remove(f"{dirname}/pool.json")
    if os.path.exists(f"{dirname}/peers.txt"):
        os.remove(f"{dirname}/peers.txt")
    if os.path.exists(dirname):
        os.rmdir(dirname)

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

# Stop the nodes
for process in processes:
    process.terminate()
    process.wait()