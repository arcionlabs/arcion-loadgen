// create arcsrc db and user
db = db.getSiblingDB("arcsrc");
db.dropUser("arcsrc")
db.createUser(
    {
        user: "arcsrc",
        pwd: "password",
        roles: [
            { role: 'dbOwner', db: 'arcsrc' },
            { role: 'read', db: 'config' },
            { role: 'read', db: 'local' }
        ]
    }
);