# NoSQL Cluster Project

This project demonstrates a fully sharded MongoDB cluster setup with secure internal authentication, routing through `mongos`, and load balancing via NGINX. It also includes Python scripts for managing PDF files in MongoDB (via base64 documents or GridFS).

---

## 📁 Project Structure

```
noSQL/
├── mongodb_cluster
│   ├── config-server/
│   │   ├── Dockerfile             # Dockerfile for config server container
│   │   ├── configsvr.conf         # mongod config for config server mode
│   │   ├── entrypoint.sh          # Init & startup logic for config servers
│   │   └── keyfile                # Shared keyfile for internal cluster auth
│   ├── mongos/
│   │   ├── Dockerfile             # Dockerfile for mongos router
│   │   ├── entrypoint.sh          # Script that waits for PRIMARY and registers shards
│   │   ├── keyfile                # Shared keyfile for mongos
│   │   └── mongos.conf            # mongos router config
│   ├── nginx/
│   │   └── nginx.conf             # NGINX config for load balancing mongos
│   ├── shard/
│   │   ├── Dockerfile             # Dockerfile for a shard replica set container
│   │   ├── entrypoint.sh          # Entrypoint running Supervisor and multiple mongod nodes
│   │   ├── init-shard.sh          # Initializes shard replica sets and users
│   │   ├── keyfile                # Shared keyfile for shard replica set auth
│   │   ├── mongod1.conf.template  # mongod config for first node
│   │   ├── mongod2.conf.template  # mongod config for second node
│   │   ├── mongod3.conf.template  # mongod config for third node
│   │   └── supervisord.conf.template # Supervisor configuration for managing mongod processes
│   ├── .env                       # Environment variables for all cluster components
│   └── docker-compose.yml         # Docker Compose orchestration
├── scripts
│   ├── files/
│   │   └── pdf/
│   │       ├── RUR_Rossumovi_Universalni_Roboty.pdf
│   │       ├── zadání 1W.pdf
│   │       ├── zadání 2.pdf
│   │       └── zadání 3 (1).pdf
│   ├── pdf/
│   │   ├── __pycache__/
│   │   │   └── store_pdf.cpython-311.pyc
│   │   ├── installed              # Marker file for installed dependencies
│   │   ├── delete.py              # Delete PDF files from DB by filename or ID
│   │   ├── load.py                # Download PDF files from DB to local directory
│   │   ├── store_pdf.py           # Core logic: upload, retrieve, delete, GridFS support
│   │   └── upload.py              # Upload local PDF files to MongoDB
│   └── .env                       # MongoDB credentials and DB config for scripts
├── .gitignore
└── README.md
```

---

## 🧩 Key Components

### 🔗 MongoDB Cluster

- **Config Servers (`config-server`)**  
  Hosts the `mongod` config servers with replica set initialization and authorization. Uses a shared keyfile for cluster internal authentication.

- **Shards (`shard`)**  
  Each shard runs as a 3-node replica set (mongod1, mongod2, mongod3), initialized and supervised via Supervisor and `init-shard.sh`.

- **Query Routers (`mongos`)**  
  `mongos` processes connect to all config servers and route queries to appropriate shards. Each instance registers shards dynamically once the config replica set is initialized.

- **NGINX Load Balancer (`nginx`)**  
  Balances requests between multiple `mongos` routers. Configuration can be extended to enable external connections via a single point of access (e.g., `localhost:8080` → mongos1/mongos2).

---

# 🔐 Authorization and Security

This MongoDB sharded cluster employs internal **keyfile-based authentication**, ensuring secure communication between cluster components (Config Servers, Shards, and Mongos routers). Additionally, an admin user is created automatically upon initial setup for external access.

## Keyfile Authentication

- Each component (Config Servers, Shards, Mongos) contains a shared secret file (`keyfile`) located in their respective directories.
- Permissions on `keyfile` are set to `400` (read-only by owner) to satisfy MongoDB security requirements.

## User Authentication

- An **admin user** is automatically created with the credentials defined in the `.env` file (`MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD`).
- External users and Python scripts must authenticate using these credentials.
- Authorization database: `admin`.

---

# 🐳 Docker Compose Setup

The entire cluster setup is orchestrated by the provided `docker-compose.yml`. It deploys:

- **3 Config Servers**: A single replica set (`configReplSet`).
- **3 Shards**: Each shard is a replica set of three `mongod` nodes (shard1, shard2, shard3).
- **2 Mongos Routers**: Automatically detect and connect to the config servers and register shards.
- **1 NGINX Load Balancer**: Distributes requests between mongos routers on port `27080`.

### Ports Overview (Exposed on localhost):

| Service        | Ports Exposed                   |
|----------------|---------------------------------|
| Config Servers | `27019`, `27020`, `27021`       |
| Shards         | Ports ranging from `27100-27302`|
| Mongos         | Default MongoDB port `27017` (internal) |
| **NGINX**      | **`27080`** (Load Balancer)     |

### Starting the Cluster

```bash
cd mongodb_cluster
docker-compose up --build
```

---

# 🌐 NGINX Load Balancer (Port 27080)

NGINX acts as the primary entry point to your sharded MongoDB cluster by balancing queries between multiple Mongos instances. 

**Connection URI:**

```bash
mongodb://<MONGO_INITDB_ROOT_USERNAME>:<MONGO_INITDB_ROOT_PASSWORD>@localhost:27080/?authSource=admin
```

**Example:**  
```bash
mongodb://admin:password123@localhost:27080/?authSource=admin
```

Replace `admin` and `password123` with the actual credentials you've specified in your `.env` file.

---

## 🐍 PDF Management via Python Scripts

The Python scripts allow upload, retrieval, and deletion of PDF files from the `main.pdf` collection.

### Storage Behavior
- PDFs ≤ 16 MB: stored directly as base64-encoded documents.
- PDFs > 16 MB: stored using GridFS.

### 🛠 Usage

> From the project root, run the following commands:

- **Upload Files**
  ```bash
  python scripts/pdf/upload.py
  ```

- **Download Files**
  ```bash
  python scripts/pdf/load.py
  ```

- **Delete Files**
  ```bash
  python scripts/pdf/delete.py
  ```

Configure connection details via `scripts/.env`.

---

## ✅ Notes

- Keyfiles are used for internal authentication between nodes.
- Authorization is enabled — only users created during initialization can access the cluster.
- `mongos` does not store data — it acts as a router only.
- NGINX can be further configured to add SSL/TLS termination, rate limiting, etc.

Here's the updated `README.md` that provides detailed information about authorization, updated Docker Compose details, and NGINX with the correct port `27080`:

