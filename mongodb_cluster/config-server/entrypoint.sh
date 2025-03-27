#!/bin/bash
set -e

echo "🚀 Starting mongod (config server) without authorization..."
mongod --config /etc/mongod.conf --fork --logpath /var/log/mongodb.log

echo "⏳ Waiting for mongod to listen on port 27019..."
until nc -z localhost 27019; do
  echo "⌛ Waiting for localhost:27019..."
  sleep 2
done

if [ "$INIT_CONFIG" == "true" ]; then
  echo "🔍 Checking replica set status..."
  ALREADY_INITIALIZED=$(mongosh --port 27019 --quiet --eval 'try{rs.status().ok}catch(e){print(e.codeName)}')

  if [ "$ALREADY_INITIALIZED" == "NotYetInitialized" ]; then
    echo "⏳ Waiting for configsvr2 and configsvr3 to start listening on port 27019..."
    until nc -z configsvr2 27019 && nc -z configsvr3 27019; do
      echo "⌛ configsvr2 or configsvr3 not ready yet..."
      sleep 2
    done

    echo "⏳ Waiting for configsvr2 and configsvr3 to become available through rs.status()..."
    until mongosh --host configsvr2 --port 27019 --quiet --eval "try { rs.status() } catch(e) { false }" && \
          mongosh --host configsvr3 --port 27019 --quiet --eval "try { rs.status() } catch(e) { false }"; do
      echo "⌛ Replicas not ready yet..."
      sleep 2
    done

    echo "⚙️ Initializing replica set 'configReplSet'..."
    mongosh --quiet --port 27019 --eval "
rs.initiate({
  _id: 'configReplSet',
  configsvr: true,
  members: [
    { _id: 0, host: 'configsvr1:27019' },
    { _id: 1, host: 'configsvr2:27019' },
    { _id: 2, host: 'configsvr3:27019' }
  ]
});
"

    echo "⏳ Waiting for PRIMARY election..."
    until mongosh --quiet --port 27019 --eval 'rs.isMaster().ismaster' | grep -q true; do
      echo "⌛ PRIMARY not elected yet, waiting..."
      sleep 3
    done
    echo "✅ PRIMARY elected!"

    echo "🔐 Creating admin user..."
    mongosh --quiet --port 27019 --eval "
db.getSiblingDB('admin').createUser({
  user: '${MONGO_INITDB_ROOT_USERNAME}',
  pwd: '${MONGO_INITDB_ROOT_PASSWORD}',
  roles: [{ role: 'root', db: 'admin' }]
});
"
    echo "✅ Configuration and admin user created successfully!"
  else
    echo "⚠️ Replica set already initialized (status: $ALREADY_INITIALIZED)."
  fi
fi

echo "🛑 Stopping mongod to restart with authorization..."
mongod --dbpath /data/configdb --shutdown

echo "🔒 Restarting mongod with authorization enabled..."
exec mongod --config /etc/mongod.conf --auth
