FROM mongo:6.0

# Устанавливаем supervisor, netcat (если потребуется для ожидания) и другие утилиты
RUN apt-get update && apt-get install -y supervisor netcat gettext

# Создаем каталоги для хранения данных
RUN mkdir -p /data/db1 /data/db2 /data/db3

# Копируем все шаблонные конфигурационные файлы и скрипты
COPY mongod1.conf.template /template/mongod1.conf.template
COPY mongod2.conf.template /template/mongod2.conf.template
COPY mongod3.conf.template /template/mongod3.conf.template
COPY supervisord.conf.template /template/supervisord.conf.template
COPY init-shard.sh /init-shard.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /init-shard.sh /entrypoint.sh

EXPOSE 27100 27101 27102

CMD ["/entrypoint.sh"]
