# Sister;Lab — Part B, Phase 2

A collection of advanced systems programming lab exercises completed as part of the Sistem Terdistribusi (Sister) lab selection at ITB. Phase 2 covers lower-level systems topics including assembly, blockchain, and legacy enterprise stacks.

---

## Contents

### 1. Assembly Web Server
A minimal HTTP web server written in x86-64 assembly. Handles GET requests for static files and POST requests to `/submit`. Demonstrates raw syscall usage for socket programming without any C standard library.

**Features:**
- Serves static HTML files with correct `Content-Type` headers
- Serves other files as downloads
- Handles 404 responses
- Accepts POST data to `/submit` and appends to `posts.txt`
- Note: supports response bodies up to 1024 bytes

**Build and run:**
```bash
make
```

**Demo:** included in `docs/images/`

---

### 2. DokiDoki
A short writing exercise.

---

### 5. MurinCoin — Blockchain Implementation
A minimal proof-of-work blockchain built in Python with a Flask REST API. Nodes communicate peer-to-peer and can mine blocks, sync chains, and validate the distributed ledger.

**Requirements:** Python 3, Flask, requests

**Setup:**
```bash
pip install flask requests
```

**Start a node:**
```bash
python src/node.py --name <node_directory> --port <port_number>
```

Example:
```bash
python src/node.py --name node1 --port 5000
```

---

### 6. Boat Goes Binted
A networking or simulation exercise. Demo video available.

**Demo:** https://youtu.be/ywMTI2lxuEY

---

### 7. Legacy — COBOL Banking App on Docker & Kubernetes
A COBOL banking application containerized with Docker and orchestrated with Kubernetes (minikube). Features a Python/uvicorn HTTP wrapper, periodic interest application via a background bash task, and public HTTPS exposure through ngrok.

**Features:**
- COBOL core logic with `--apply-interest` argument
- Interest applied every 23 seconds via background shell task in Dockerfile
- Kubernetes deployment via minikube
- HTTPS public URL via ngrok reverse proxy

**Run with Docker:**
```bash
docker build -t legacy .
docker run -p 8000:8000 legacy
```

---

## License
MIT
