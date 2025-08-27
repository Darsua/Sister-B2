### Peer discovery test script

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

# Stop the nodes
for process in processes:
    process.terminate()
    process.wait()