// create arcdst db and user
db = db.getSiblingDB("arcdst");
db.dropUser("arcdst")
db.createUser(
    {
        user: "arcdst",
        pwd: "password",
        roles: [
            { role: 'dbOwner', db: 'arcdst' },
            { role: 'read', db: 'config' },
            { role: 'read', db: 'local' }
        ]
    }
);