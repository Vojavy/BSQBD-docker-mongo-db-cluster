# NoSQL Cluster Project

This project demonstrates a sharded MongoDB cluster that includes three config servers, three shard replica sets, and a mongos router. It also includes sample PDF files and Python scripts for managing these PDFs (upload, load, and delete).

---

## Project Structure

```
noSQL/
├── files
│   └── pdf
│       ├── RUR_Rossumovi_Universalni_Roboty.pdf
│       ├── zadání 1W.pdf
│       ├── zadání 2.pdf
│       └── zadání 3 (1).pdf
├── mongodb_cluster
│   ├── config-server
│   │   ├── Dockerfile             # Dockerfile for the config server container
│   │   ├── configsvr.conf         # Configuration file for mongod in config server mode
│   │   └── entrypoint.sh          # Entrypoint script for starting and initializing the config server
│   ├── mongos
│   │   ├── Dockerfile             # Dockerfile for the mongos container
│   │   ├── entrypoint.sh          # Entrypoint script for starting mongos and registering shards
│   │   └── mongos.conf            # Configuration file for mongos
│   ├── shard
│   │   ├── Dockerfile             # Dockerfile for the shard container
│   │   ├── entrypoint.sh          # Entrypoint script for the shard container (using Supervisor)
│   │   ├── init-shard.sh          # Script to initialize the shard replica set
│   │   ├── mongod1.conf.template  # Template configuration for the first mongod instance in a shard
│   │   ├── mongod2.conf.template  # Template configuration for the second mongod instance in a shard
│   │   ├── mongod3.conf.template  # Template configuration for the third mongod instance in a shard
│   │   └── supervisord.conf.template  # Template configuration for Supervisor
│   ├── .env                       # Environment variables file for cluster configuration
│   └── docker-compose.yml         # Docker Compose file for orchestrating the cluster
└── scripts
    └── pdf
        ├── delete.py              # Script with the Deleter class for removing PDFs from the database
        ├── load.py                # Script with the Loader class for retrieving PDFs from the database to a local folder
        ├── store_pdf.py           # Module with functions to upload, retrieve, delete, and get the size of PDF files
        └── upload.py              # Script to upload PDF files from the local filesystem into the database
```

---

## Key Components

### MongoDB Cluster (mongodb_cluster)

- **Config Servers (config-server):**  
  These run `mongod` in config server mode. They include a Dockerfile, a configuration file (`configsvr.conf`), and an entrypoint script (`entrypoint.sh`) to initialize the replica set.

- **Mongos (mongos):**  
  This is the query router for the sharded cluster. It includes a Dockerfile, a configuration file (`mongos.conf`), and an entrypoint script (`entrypoint.sh`) for starting mongos and registering shards.

- **Shards (shard):**  
  Each shard consists of a replica set with three `mongod` instances. The shard folder contains Dockerfile, an entrypoint script (which uses Supervisor to manage the processes), a shard initialization script (`init-shard.sh`), and template configuration files for the individual mongod instances and Supervisor.

- **.env and docker-compose.yml:**  
  These files define environment variables and orchestrate all services (config servers, shards, and mongos) respectively.

### Files (files/pdf)

Contains sample PDF files used for testing the upload, load, and deletion operations via Python scripts.

### Python Scripts (scripts/pdf)

- **store_pdf.py:**  
  Contains functions for uploading PDF files to the database (either as Base64-encoded documents in the `pdf` collection or using GridFS for large files), retrieving files, deleting files, and getting file sizes.

- **upload.py:**  
  Imports functions from `store_pdf.py` and uploads PDF files from the local filesystem into the database.

- **load.py:**  
  Implements a Loader class that retrieves PDF files by filename from the database and saves them to a local directory (e.g., `loaded`).

- **delete.py:**  
  Implements a Deleter class that removes PDF files from the database by filename or _id.

---

## How to Use

### Running the Cluster

1. Navigate to the `mongodb_cluster` directory.
2. Run Docker Compose to start the entire cluster:
   ```bash
   docker-compose up
   ```

This command will launch the config servers, shard replica sets, and the mongos router.

### Managing PDF Files

- **Uploading Files:**  
  Run the upload script to insert PDFs from the local filesystem into the database:
  ```bash
  python scripts/pdf/upload.py
  ```

- **Loading (Retrieving) Files:**  
  Run the load script to retrieve files by name and save them to a local folder (e.g., `loaded`):
  ```bash
  python scripts/pdf/load.py
  ```

- **Deleting Files:**  
  Run the delete script to remove files from the database:
  ```bash
  python scripts/pdf/delete.py
  ```

Files smaller than or equal to 16 MB are stored as Base64-encoded documents in the `pdf` collection of the `main` database. Larger files are stored using GridFS.

---

## Notes

- This version does not yet include detailed authentication documentation (the current stable version is uploaded to GitHub without those details).
- The Python scripts in the `scripts/pdf` folder provide functionality to upload, retrieve, and delete PDF files in the `main` database.

---
