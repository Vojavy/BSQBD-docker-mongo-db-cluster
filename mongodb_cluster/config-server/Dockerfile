FROM mongo:6.0

EXPOSE 27019

RUN apt-get update && apt-get install -y netcat

COPY configsvr.conf /etc/mongod.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
