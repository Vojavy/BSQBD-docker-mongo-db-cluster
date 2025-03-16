#!/bin/bash
set -e

echo "Запускаем mongos с конфигурационным файлом..."
mongos --config /etc/mongos.conf &
MONGOS_PID=$!

echo "Ожидание, пока mongos начнет прослушивать порт 27017..."
while ! nc -z localhost 27017; do
  echo "mongos ещё не готов, ждем..."
  sleep 2
done

echo "mongos запущен. Начинаем регистрацию шардов..."

# Определяем требуемые шарды
REQUIRED_SHARDS=("shard1" "shard2" "shard3")

# Функция для добавления конкретного шарда
add_shard() {
  shard=$1
  if [ "$shard" == "shard1" ]; then
    echo "Добавляем shard1..."
    mongosh --quiet --port 27017 --eval "sh.addShard('shard1/shard1:27100,shard1:27101,shard1:27102')"
  elif [ "$shard" == "shard2" ]; then
    echo "Добавляем shard2..."
    mongosh --quiet --port 27017 --eval "sh.addShard('shard2/shard2:27100,shard2:27101,shard2:27102')"
  elif [ "$shard" == "shard3" ]; then
    echo "Добавляем shard3..."
    mongosh --quiet --port 27017 --eval "sh.addShard('shard3/shard3:27100,shard3:27101,shard3:27102')"
  fi
}

# Основной цикл проверки регистрации шардов
while true; do
  echo "Проверка зарегистрированных шардов..."
  # Получаем список shard-идентификаторов как строку, разделённую запятыми
  CURRENT_SHARDS=$(mongosh --quiet --port 27017 --eval "var s=db.adminCommand({listShards:1}).shards.map(function(x){return x._id;}); print(s.join(','));")
  echo "Текущие шарды: $CURRENT_SHARDS"
  
  missing=()
  for shard in "${REQUIRED_SHARDS[@]}"; do
    if ! echo "$CURRENT_SHARDS" | grep -q "$shard"; then
      missing+=("$shard")
    fi
  done

  if [ ${#missing[@]} -eq 0 ]; then
    echo "Все шарды зарегистрированы."
    break
  fi

  echo "Отсутствуют шарды: ${missing[*]}. Пытаемся добавить их..."
  for shard in "${missing[@]}"; do
    add_shard "$shard"
  done
  
  echo "Ожидание 10 секунд перед повторной проверкой..."
  sleep 10
done

echo "Инициализация шардов завершена. Mongos запущен."
wait $MONGOS_PID
