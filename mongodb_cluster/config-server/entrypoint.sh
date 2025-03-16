#!/bin/bash
set -e

echo "Запускаем mongod как config сервер..."
mongod --configsvr --replSet configReplSet --config /etc/mongod.conf &
MONGOD_PID=$!

echo "Ожидание, пока mongod начнет прослушивать порт 27019..."
while ! nc -z localhost 27019; do
  echo "mongod еще не готов, ждем..."
  sleep 2
done

# Инициализацию выполняем только если переменная INIT_CONFIG равна true.
if [ "$INIT_CONFIG" == "true" ]; then
  echo "mongod запущен. Выполняем инициализацию репликационного набора config-сервера..."
  /usr/bin/mongosh --port 27019 <<EOF
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "configsvr1:27019" },
    { _id: 1, host: "configsvr2:27019" },
    { _id: 2, host: "configsvr3:27019" }
  ]
})
EOF
  echo "Инициализация завершена."
fi

echo "Переходим к основному процессу..."
wait $MONGOD_PID
