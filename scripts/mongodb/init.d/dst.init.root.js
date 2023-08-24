// create arcdst db and user
db = db.getSiblingDB("${DSTDB_ARC_USER}");
db.dropUser("${DSTDB_ARC_USER}")
db.createUser(
    {
        user: "${DSTDB_ARC_USER}",
        pwd: "${DSTDB_ARC_PW}",
        roles: [
            { role: 'dbOwner', db: '${DSTDB_ARC_USER}' },
            { role: 'read', db: 'config' },
            { role: 'read', db: 'local' }
        ]
    }
);