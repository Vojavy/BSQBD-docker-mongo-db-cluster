# 📚 MongoDB Sharded Cluster Project

This project demonstrates a comprehensive sharded MongoDB cluster setup, including secured internal authentication, dynamic routing through multiple `mongos` routers, and load balancing with NGINX. It includes automated data initialization with validation schemas, multiple sample datasets, Python scripts for dataset management, and a JupyterLab notebook for data analysis and visualization.

---

## 📁 Project Structure

```
noSQL/
├── Data
│   ├── files
│   │   └── data-sets
│   │       ├── Indian_Traffic_Violations.csv
│   │       ├── Mastercard_stock_history.csv
│   │       └── Netflix_films.csv
│   └── scripts
│       ├── .env
│       ├── data_analysis_notebook.ipynb
│       ├── upload_indian_traffic.py
│       ├── upload_mastercard_stock.py
│       └── upload_netflix_films.py
├── Queries
│   ├── cards.txt
│   ├── indians.txt
│   └── netflix.txt
├── mongodb_cluster
│   ├── config-server
│   │   ├── Dockerfile
│   │   ├── configsvr.conf
│   │   ├── entrypoint.sh
│   │   └── keyfile
│   ├── mongos
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   ├── keyfile
│   │   ├── mongos.conf
│   │   └── schema-collections-init.sh
│   ├── nginx
│   │   └── nginx.conf
│   ├── shard
│   │   ├── Dockerfile
│   │   ├── entrypoint.sh
│   │   ├── init-shard.sh
│   │   ├── keyfile
│   │   ├── mongod1.conf.template
│   │   ├── mongod2.conf.template
│   │   ├── mongod3.conf.template
│   │   └── supervisord.conf.template
│   ├── .env
│   └── docker-compose.yml
├── .gitignore
└── README.md
```

---

## 🚀 Key Components and Architecture

### 🔗 MongoDB Cluster Structure

The cluster includes:

- **Config Servers (`config-server`)**  
  Three-node replica set (`configReplSet`) responsible for storing metadata about shards and clusters.

- **Shards (`shard`)**  
  Three individual replica sets (shard1, shard2, shard3), each running three MongoDB nodes managed by Supervisor. They store and distribute actual data.

- **Query Routers (`mongos`)**  
  Two mongos routers automatically detect and register shard clusters, routing client queries accordingly.

- **NGINX Load Balancer (`nginx`)**  
  Balances client connections across available mongos instances, accessible externally on port `27080`.

---

## 🔐 Security and Authentication

The project implements MongoDB's internal authentication using shared keyfiles. It also creates an administrative user for external access.

### Keyfile-Based Authentication

- Shared `keyfile` securely distributed across cluster components (`config-server`, `shard`, `mongos`).
- Permissions strictly set to `400`.

### Admin User Authentication

- Credentials stored in `.env` file (`MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`).
- Authenticated via MongoDB's `admin` database.

---

## 🐳 Docker Compose Setup

The Docker Compose configuration deploys:

- **Config Servers**: `configsvr1`, `configsvr2`, `configsvr3`  
  Ports: `27019`, `27020`, `27021`

- **Shards**: Three replica sets (`shard1`, `shard2`, `shard3`)  
  Ports: `27100-27302`

- **Mongos Routers**: Two instances (`mongos1`, `mongos2`)  
  Internal Port: `27017` and externally load balanced via NGINX on port `27080`

### 🔧 Running the Cluster

To build and run the entire cluster:

```bash
cd mongodb_cluster
docker-compose up --build
```

---

## 🌐 Connecting Through NGINX (Load Balancer)

Clients and applications connect through NGINX on port `27080`.

**Connection String:**

```bash
mongodb://<MONGO_INITDB_ROOT_USERNAME>:<MONGO_INITDB_ROOT_PASSWORD>@localhost:27080/?authSource=admin
```

Example:

```bash
mongodb://admin:YourStrongPassword@localhost:27080/?authSource=admin
```

---

## 📂 Datasets and Validation Schemas

Three datasets have been integrated with appropriate MongoDB JSON schema validation:

- 📺 **Netflix films**  
- 🚦 **Indian traffic violations**  
- 📈 **Mastercard stock prices**

The datasets are located in the `Data/files/data-sets` directory, and can be loaded into MongoDB using provided Python scripts.

---

## 🐍 Python Scripts for Data Upload

The scripts to upload datasets are located under `Data/scripts`:

```bash
python upload_netflix_films.py
python upload_indian_traffic.py
python upload_mastercard_stock.py
```

Ensure MongoDB credentials are configured in `Data/scripts/.env`.

---

## 📊 Data Analysis Notebook (JupyterLab)

The provided Jupyter Notebook (`data_analysis_notebook.ipynb`) offers exploratory data analysis and visualization of the three datasets.

### 🚀 Setup JupyterLab Environment

Install required packages:

```bash
pip install jupyterlab pymongo pandas matplotlib seaborn
```

Launch JupyterLab:

```bash
jupyter lab
```

Run the notebook (`data_analysis_notebook.ipynb`) to view and interact with data analyses and visualizations.

---

## 📜 Queries (MongoDB Aggregations & Operations)

Prepared complex queries covering filtering, aggregation, updating, deleting, indexing, and optimization are stored in:

- 📺 Netflix queries (`Queries/netflix.txt`)
- 🚦 Indian traffic queries (`Queries/indians.txt`)
- 📈 Mastercard queries (`Queries/cards.txt`)

---

## 📌 Additional Information & Recommendations

- The entire solution is fully containerized, making it platform-independent.
- NGINX configuration can be expanded to add security layers (SSL/TLS).
- Data persistence is managed through Docker volumes.

---

## ✅ Conclusion

This MongoDB cluster setup demonstrates robust NoSQL practices, including sharding, replication, high availability, data validation, and secured communication between cluster nodes. It supports extensive data operations, automated scripts, detailed analytics, and visualizations.
