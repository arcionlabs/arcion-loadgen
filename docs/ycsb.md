
# ycsb

```bash
git checkout jdbc_url_delim
mvn -pl site.ycsb:jdbc-binding -am clean package
cp jdbc/target/ycsb-jdbc-binding-0.18.0-SNAPSHOT.tar.gz ~/github/arcion/docker-dev/arcion-demo-test/arcion-share/loadgen/.
```

inside the container
```bash
cd /opt/ycsb
gzip -dc /opt/stage/data/ycsb-jdbc-binding-0.18.0-SNAPSHOT.tar.gz | tar -xvf -
