#!/bin/bash
set -e

echo "Waiting for shard mongod instance to start (port 27100)..."
until nc -z localhost 27100; do sleep 2; done

ALREADY_INITIALIZED=$(mongosh --quiet --port 27100 --eval "try { print(rs.status().ok) } catch(e) { print(0) }" || echo "0")
if [ "$ALREADY_INITIALIZED" != "1" ]; then
  echo "Initializing replica set ${REPLICA_SET_NAME} and creating user..."
  mongosh --port 27100 <<EOF
rs.initiate({
  _id: "${REPLICA_SET_NAME}",
  members: [
    { _id: 0, host: "${REPLICA_SET_NAME}:27100" },
    { _id: 1, host: "${REPLICA_SET_NAME}:27101" },
    { _id: 2, host: "${REPLICA_SET_NAME}:27102" }
  ]
});
sleep(5000);
db.getSiblingDB("admin").createUser({
  user: "${MONGO_INITDB_ROOT_USERNAME}",
  pwd: "${MONGO_INITDB_ROOT_PASSWORD}",
  roles: [{ role: "root", db: "admin" }]
});
EOF
  echo "Replica set and user successfully created."
else
  echo "Replica set already initialized."
fi
