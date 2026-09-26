# Systems & Infrastructure Suite (Sister-B2)

A suite of low-level systems programming and infrastructure implementations completed for the Parallel & Distributed Systems Laboratory (Lab Sister) selection at ITB. Covers bare-metal x86-64 assembly, peer-to-peer distributed ledgers, and containerized legacy enterprise workloads on Kubernetes.

---

## Implementations

### 1. Bare-Metal Assembly Web Server (x86-64)
A minimal HTTP 1.1 web server implemented in raw x86-64 assembly using Linux kernel syscalls (`sys_socket`, `sys_bind`, `sys_listen`, `sys_accept`, `sys_read`, `sys_write`) without libc or external runtime dependencies.

- **Routing & HTTP Parsing:** Serves static HTML files with MIME `Content-Type` headers, serves binary downloads, and routes POST submissions to `/submit`.
- **Error Handling:** Returns compliant HTTP 404 responses for non-existent routes.
- **Persistence:** Parses and appends incoming POST request payloads directly to disk storage (`posts.txt`).

**Build & Run:**
```bash
make
./server
```

---

### 2. MurinCoin — Proof-of-Work Blockchain Node
A decentralized peer-to-peer distributed ledger built in Python featuring cryptographic block validation, consensus-driven chain synchronization, and a Flask REST API.

- **Proof-of-Work Mining:** Computes cryptographic SHA-256 hashes matching dynamic difficulty targets.
- **Peer-to-Peer Consensus:** Longest-chain consensus rule to resolve conflicting forks across distributed peers.
- **REST Telemetry:** Endpoints for mining new blocks, inspecting chain validity, and broadcasting transactions.

**Setup & Start Node:**
```bash
pip install flask requests
python src/node.py --name node1 --port 5000
```

---

### 3. Legacy — Containerized COBOL Banking on Kubernetes
A legacy COBOL transactional banking engine modernized and containerized with Docker and orchestrated on Kubernetes (Minikube).

- **Core Engine:** Procedural COBOL logic executing account balancing, transactions, and periodic compound interest calculation (`--apply-interest`).
- **Modern API Gateway:** Python ASGI (Uvicorn) wrapper exposing RESTful HTTP endpoints interfacing with the compiled COBOL binary.
- **Kubernetes Orchestration:** Managed through declarative Kubernetes manifests (Deployments, Pods, Services) for high-availability scheduling.

**Run with Docker:**
```bash
docker build -t legacy .
docker run -p 8000:8000 legacy
```

---

## Additional Lab Exercises
- **Boat Goes Binted:** Networking simulation and protocol inspection ([Demo Video](https://youtu.be/ywMTI2lxuEY)).
- **DokiDoki:** Technical writing and documentation exercise.

---

## License
MIT
