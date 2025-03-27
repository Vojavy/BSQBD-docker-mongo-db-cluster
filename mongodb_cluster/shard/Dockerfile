FROM mongo:6.0
RUN apt-get update && apt-get install -y supervisor netcat gettext
RUN mkdir -p /data/db1 /data/db2 /data/db3
COPY mongod1.conf.template /template/mongod1.conf.template
COPY mongod2.conf.template /template/mongod2.conf.template
COPY mongod3.conf.template /template/mongod3.conf.template
COPY supervisord.conf.template /template/supervisord.conf.template
COPY init-shard.sh /init-shard.sh
COPY entrypoint.sh /entrypoint.sh
COPY keyfile /data/keyfile
RUN chmod 400 /data/keyfile && chown 999:999 /data/keyfile
RUN chmod +x /init-shard.sh /entrypoint.sh
EXPOSE 27100 27101 27102
CMD ["/entrypoint.sh"]
