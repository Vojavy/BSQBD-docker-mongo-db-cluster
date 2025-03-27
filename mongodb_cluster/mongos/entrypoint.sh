#!/bin/bash
set -e

CONFIG_SERVERS=("configsvr1" "configsvr2" "configsvr3")
PRIMARY_HOST=""

echo "🔍 Searching for PRIMARY among config servers..."

wait_for_primary() {
  while true; do
    for host in "${CONFIG_SERVERS[@]}"; do
      # Check if port is listening (mongod is running)
      if ! nc -z "$host" 27019; then
        continue
      fi

      # Attempt to connect to mongod and check if it's PRIMARY
      is_primary=$(mongosh --host "$host" --port 27019 \
        --quiet \
        -u "$MONGO_INITDB_ROOT_USERNAME" \
        -p "$MONGO_INITDB_ROOT_PASSWORD" \
        --authenticationDatabase admin \
        --eval "try { rs.isMaster().ismaster } catch(e) { false }" 2>/dev/null || echo "false")

      if [ "$is_primary" == "true" ]; then
        PRIMARY_HOST="$host"
        echo "✅ PRIMARY found: $PRIMARY_HOST"
        return
      fi
    done

    echo "❌ PRIMARY not found. Waiting 5 seconds before retrying..."
    sleep 5
  done
}

wait_for_primary

echo "Checking admin user availability..."
until mongosh --host "$PRIMARY_HOST" --port 27019 \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin --quiet \
  --eval "db.adminCommand('ping')" | grep -q "ok"; do
  echo "Waiting for admin user to become available..."
  sleep 5
done
echo "Admin user is available."

echo "🚀 Launching mongos with configuration file..."
mongos --config /etc/mongos.conf &
MONGOS_PID=$!

echo "⏳ Waiting for mongos to start listening on port 27017..."
until nc -z localhost 27017; do 
  sleep 2
done
echo "✅ Mongos is running."

if [ "$REGISTER_SHARDS" == "true" ]; then
  echo "🔧 Shard registration mode is enabled."

  REQUIRED_SHARDS=("${SHARD1_NAME}" "${SHARD2_NAME}" "${SHARD3_NAME}")

  add_shard() {
    shard=$1
    shard_hosts="$shard:27100,$shard:27101,$shard:27102"
    echo "➕ Adding shard '$shard' with hosts: $shard_hosts"
    mongosh --quiet --port 27017 \
      -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
      --authenticationDatabase admin \
      --eval "sh.addShard('$shard/$shard_hosts')"
  }

  while true; do
    echo "🔍 Checking registered shards..."
    CURRENT_SHARDS=$(mongosh --quiet --port 27017 \
      -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
      --authenticationDatabase admin \
      --eval "try { db.adminCommand({listShards:1}).shards.map(x => x._id).join(',') } catch(e) { '' }")

    echo "✅ Current shards: $CURRENT_SHARDS"
    
    missing=()
    for shard in "${REQUIRED_SHARDS[@]}"; do
      if ! echo "$CURRENT_SHARDS" | grep -qw "$shard"; then
        missing+=("$shard")
      fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
      echo "🎉 All shards successfully registered."
      break
    fi

    echo "➕ Missing shards: ${missing[*]}. Adding them..."
    for shard in "${missing[@]}"; do
      add_shard "$shard"
    done

    echo "🔄 Waiting 10 seconds before rechecking..."
    sleep 10
  done
else
  echo "ℹ️ REGISTER_SHARDS not set to true. Skipping shard registration."
fi

echo "🟢 Mongos is fully operational."
wait $MONGOS_PID
