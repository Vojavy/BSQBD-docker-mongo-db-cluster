FROM mongo:6.0
EXPOSE 27017
RUN apt-get update && apt-get install -y netcat-openbsd
COPY mongos.conf /etc/mongos.conf
COPY entrypoint.sh /entrypoint.sh
COPY keyfile /data/keyfile
RUN chmod 400 /data/keyfile && chown 999:999 /data/keyfile
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
