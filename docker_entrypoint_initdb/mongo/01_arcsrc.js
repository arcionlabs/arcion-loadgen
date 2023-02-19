// create arcsrc db and user
db = db.getSiblingDB("arcsrc");
db.createUser(
    {
        user: "arcsrc",
        pwd: "password",
        roles: [
            { role: 'dbOwner', db: 'arcsrc' }
        ]
    }
);
// create arcdst db and user
db = db.getSiblingDB("arcdst");
db.createUser(
    {
        user: "arcdst",
        pwd: "password",
        roles: [
            { role: 'dbOwner', db: 'arcdst' }
        ]
    }
);


