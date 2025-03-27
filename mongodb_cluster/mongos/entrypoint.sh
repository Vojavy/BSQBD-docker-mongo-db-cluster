#!/bin/bash
set -e

CONFIG_SERVERS=("configsvr1" "configsvr2" "configsvr3")
PRIMARY_HOST=""

echo "🔍 Ищем PRIMARY среди config-серверов..."

wait_for_primary() {
  while true; do
    for host in "${CONFIG_SERVERS[@]}"; do
      echo "🔎 Проверяем $host:27019..."

      # Сначала проверяем, слушает ли вообще порт (mongod запущен)
      if ! nc -z "$host" 27019; then
        echo "❌ $host:27019 недоступен. Пропускаем..."
        continue
      fi

      # Пытаемся подключиться к mongod и проверить, является ли он PRIMARY
      is_primary=$(mongosh --host "$host" --port 27019 \
        --quiet \
        -u "$MONGO_INITDB_ROOT_USERNAME" \
        -p "$MONGO_INITDB_ROOT_PASSWORD" \
        --authenticationDatabase admin \
        --eval "try { rs.isMaster().ismaster } catch(e) { false }" 2>/dev/null || echo "false")

      if [ "$is_primary" == "true" ]; then
        PRIMARY_HOST="$host"
        echo "✅ Найден PRIMARY: $PRIMARY_HOST"
        return
      fi
    done

    echo "❌ PRIMARY не найден. Ждем 5 секунд и пробуем снова..."
    sleep 5
  done
}

wait_for_primary

echo "Проверяем доступность admin-пользователя..."
until mongosh --host "$PRIMARY_HOST" --port 27019 \
  -u "$MONGO_INITDB_ROOT_USERNAME" \
  -p "$MONGO_INITDB_ROOT_PASSWORD" \
  --authenticationDatabase admin --quiet \
  --eval "db.adminCommand('ping')" | grep -q "ok"; do
  echo "Ждем, пока admin-пользователь станет доступен..."
  sleep 5
done
echo "Admin-пользователь доступен."

echo "🚀 Запускаем mongos с конфигурационным файлом..."
mongos --config /etc/mongos.conf &
MONGOS_PID=$!

echo "⏳ Ждем, пока mongos начнет слушать порт 27017..."
until nc -z localhost 27017; do 
  sleep 2
done
echo "✅ mongos запущен."

if [ "$REGISTER_SHARDS" == "true" ]; then
  echo "🔧 Режим регистрации шардов включен."

  REQUIRED_SHARDS=("${SHARD1_NAME}" "${SHARD2_NAME}" "${SHARD3_NAME}")

  add_shard() {
    shard=$1
    shard_hosts="$shard:27100,$shard:27101,$shard:27102"
    echo "➕ Добавляем shard '$shard' с хостами: $shard_hosts"
    mongosh --quiet --port 27017 \
      -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
      --authenticationDatabase admin \
      --eval "sh.addShard('$shard/$shard_hosts')"
  }

  while true; do
    echo "🔍 Проверяем зарегистрированные шарды..."
    CURRENT_SHARDS=$(mongosh --quiet --port 27017 \
      -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" \
      --authenticationDatabase admin \
      --eval "try { db.adminCommand({listShards:1}).shards.map(x => x._id).join(',') } catch(e) { '' }")

    echo "✅ Текущие шарды: $CURRENT_SHARDS"
    
    missing=()
    for shard in "${REQUIRED_SHARDS[@]}"; do
      if ! echo "$CURRENT_SHARDS" | grep -qw "$shard"; then
        missing+=("$shard")
      fi
    done

    if [ ${#missing[@]} -eq 0 ]; then
      echo "🎉 Все шарды успешно зарегистрированы."
      break
    fi

    echo "➕ Отсутствуют шарды: ${missing[*]}. Добавляем их..."
    for shard in "${missing[@]}"; do
      add_shard "$shard"
    done

    echo "🔄 Ждем 10 секунд перед повторной проверкой..."
    sleep 10
  done
else
  echo "ℹ️ REGISTER_SHARDS не установлен в true. Пропускаем регистрацию шардов."
fi

echo "🟢 Mongos полностью готов к работе."
wait $MONGOS_PID
