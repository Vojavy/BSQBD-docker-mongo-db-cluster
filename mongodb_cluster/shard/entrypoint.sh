    #!/bin/bash
set -e

echo "Setting up env values..."

# Подставляем переменные в шаблоны и генерируем конфигурации
envsubst < /template/supervisord.conf.template > /etc/supervisor/conf.d/supervisord.conf
mkdir -p /etc/mongo_config
envsubst < /template/mongod1.conf.template > /etc/mongo_config/mongod1.conf
envsubst < /template/mongod2.conf.template > /etc/mongo_config/mongod2.conf
envsubst < /template/mongod3.conf.template > /etc/mongo_config/mongod3.conf

echo "Starting Supervisor..."
exec /usr/bin/supervisord -n
