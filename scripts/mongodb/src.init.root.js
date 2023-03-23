// login in mongosh mongodb://root:Passw0rd@mongodb
// create arcsrc db and user
db = db.getSiblingDB("${SRCDB_ARC_USER}");
db.dropUser("${SRCDB_ARC_USER}")
db.createUser(
    {
        user: "${SRCDB_ARC_USER}",
        pwd: "${SRCDB_ARC_PW}",
        roles: [
            { role: 'dbOwner', db: '${SRCDB_ARC_USER}' },
            { role: 'read', db: 'config' },
            { role: 'read', db: 'local' }
        ]
    }
);

// create replication set
rsconf = {
    _id: "rs0",
    members: [
      {
       _id: 0,
       host: "mongodb:27017"
      },
      {
       _id: 1,
       host: "mongodb2:27017"
      },
      {
       _id: 2,
       host: "mongodb3:27017"
      }
     ]
  }

rs.initiate( rsconf );

// shard the cluster to enable realtime replication
enableShardingOnBlitzzCollection = () => {
    db.getSiblingDB("${SRCDB_ARC_USER}");
    sh.enableSharding("${SRCDB_ARC_USER}");
    sh.shardCollection("${SRCDB_ARC_USER}.usertable", {"_id" : "hashed"})
}

enableShardingOnBlitzzCollection();
