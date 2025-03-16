FROM mongo:6.0

EXPOSE 27017

RUN apt-get update && apt-get install -y netcat-openbsd

# Копируем конфигурационный файл для mongos
COPY mongos.conf /etc/mongos.conf

# Копируем наш кастомный entrypoint-скрипт
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
