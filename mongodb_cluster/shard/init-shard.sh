#!/bin/bash
echo "Ожидаем запуска mongod1 на порту 27100..."
while ! nc -z localhost 27100; do
  echo "mongod1 не доступен, ждём 2 секунды..."
  sleep 2
done

echo "mongod1 запущен. Инициализация репликационного набора ${REPLICA_SET_NAME}..."
/usr/bin/mongosh --port 27100 <<EOF
rs.initiate({
  _id: "${REPLICA_SET_NAME}",
  members: [
    { _id: 0, host: "${REPLICA_SET_NAME}:27100" },
    { _id: 1, host: "${REPLICA_SET_NAME}:27101" },
    { _id: 2, host: "${REPLICA_SET_NAME}:27102" }
  ]
})
EOF
