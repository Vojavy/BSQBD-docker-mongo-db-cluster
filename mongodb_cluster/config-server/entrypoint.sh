#!/bin/bash
set -e

echo "🚀 Запускаем mongod (config-сервер) без авторизации..."
mongod --config /etc/mongod.conf --fork --logpath /var/log/mongodb.log

echo "⏳ Ждём, пока mongod начнёт слушать порт 27019..."
until nc -z localhost 27019; do
  echo "⌛ Ожидаем localhost:27019..."
  sleep 2
done

if [ "$INIT_CONFIG" == "true" ]; then
  echo "🔍 Проверяем статус реплика-сета..."
  ALREADY_INITIALIZED=$(mongosh --port 27019 --quiet --eval 'try{rs.status().ok}catch(e){print(e.codeName)}')

  if [ "$ALREADY_INITIALIZED" == "NotYetInitialized" ]; then
    echo "⏳ Ждём, пока configsvr2 и configsvr3 начнут слушать порт 27019..."
    until nc -z configsvr2 27019 && nc -z configsvr3 27019; do
      echo "⌛ configsvr2 или configsvr3 ещё не готовы..."
      sleep 2
    done

    echo "⏳ Ждём, пока configsvr2 и configsvr3 станут доступны через rs.status()..."
    until mongosh --host configsvr2 --port 27019 --quiet --eval "try { rs.status() } catch(e) { false }" && \
          mongosh --host configsvr3 --port 27019 --quiet --eval "try { rs.status() } catch(e) { false }"; do
      echo "⌛ Реплики ещё не готовы..."
      sleep 2
    done

    echo "⚙️  Инициализируем реплика-сет configReplSet..."
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

    echo "⏳ Ждём выбора Primary..."
    until mongosh --quiet --port 27019 --eval 'rs.isMaster().ismaster' | grep -q true; do
      echo "⌛ Primary ещё не выбран, ждём..."
      sleep 3
    done
    echo "✅ Primary выбран!"

    echo "🔐 Создаём admin-пользователя..."
    mongosh --quiet --port 27019 --eval "
db.getSiblingDB('admin').createUser({
  user: '${MONGO_INITDB_ROOT_USERNAME}',
  pwd: '${MONGO_INITDB_ROOT_PASSWORD}',
  roles: [{ role: 'root', db: 'admin' }]
});
"
    echo "✅ Конфигурация и пользователь успешно созданы!"
  else
    echo "⚠️  Реплика-сет уже инициализирован (статус: $ALREADY_INITIALIZED)."
  fi
fi

echo "🛑 Останавливаем mongod для перезапуска с авторизацией..."
mongod --dbpath /data/configdb --shutdown

echo "🔒 Перезапуск mongod с авторизацией..."
exec mongod --config /etc/mongod.conf --auth
