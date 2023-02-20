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