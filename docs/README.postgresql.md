
# postgres with SSL setup
docker run -d \
    --name postgresql \
    --network arcnet \
    -e POSTGRES_USER=root \
    -e POSTGRES_PASSWORD=Passw0rd \
    -p :5432 \
    postgres \
    -c wal_level=logical \
    -c max_replication_slots=10 \
    -c max_connections=300 \
    -c shared_buffers=80MB \
    -c ssl=on \
    -c ssl_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem \
    -c ssl_key_file=/etc/ssl/private/ssl-cert-snakeoil.key    

# wait for db to come up
while [ -z "$( docker logs postgresql 2>&1 | grep 'database system is ready to accept connections' )" ]; do sleep 10; done;

# install wal2json for cdc
docker exec -it postgresql sh -c "apt update && apt install -y postgresql-15-wal2json postgresql-contrib"
