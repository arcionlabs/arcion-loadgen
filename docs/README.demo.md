This has more explnation about the demo kit.

A host has two database and two user IDs.  The Load Generator is setup to use `arcsrc` username and write to `arcsrc` database.

```mermaid
graph LR
    L[Load Generator<br>sysbench<br>YCSB] --> arcsrc
    subgraph Source Host
        arcsrc
        arcdst
    end
   
```

Data is replicated from `arcsrc` to `arcdst` database.

```mermaid
graph LR
    subgraph Target
        das[Target arcsrc]
        dad[Target arcdst]
    end   
    subgraph Source
        sas[Source arcsrc]
        sad[Source arcdst]
    end
    sas --> Arcion
    Arcion --> dad
 
```

Source and Target can be the same host. `arcsrc` database is replicated to `arcdst` database.

```mermaid
graph TB
    subgraph Host
        arcsrc
        arcdst
    end   
    arcsrc --> Arcion
    Arcion --> arcdst
 
```
