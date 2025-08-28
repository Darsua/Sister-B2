# MurinCoin

Gigi Murin keeps me at night.

## How to Run

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/MurinCoin.git
   cd MurinCoin
   ```

2. **Install dependencies:**
   ```bash
   pip install flask requests
   ```

3. **Start a node:**
   ```bash
   python src/node.py --name <node_directory> --port <port_number>
   ```
   - `<node_directory>`: Directory for node data (e.g., `node1`)
   - `<port_number>`: Port to run the node on (default is `5000`)

   Example:
   ```bash
   python src/node.py --name node1 --port 5000
   ```

4. **Optional flags:**
   - `--no-sync`: Disable automatic chain synchronization on startup.

---

## Demo Video

https://youtu.be/ACemHjXJnDw