oracle has one user one schema.
each workload needs its own schema
each schema could have different size factors

option1)

ycsb
ycsb10
ycsb100
ycsb1k

tpcc
tpcc10
tpcc100
tpcc1k

or
option 2)*

arcsrc_ycsb
arcsrc_ycsb10
arcsrc_ycsb100
arcsrc_ycsb1k

arcsrc_tpcc
arcsrc_tpcc10
arcsrc_tpcc100
arcsrc_tpcc1k

or 
option3)

arcsrc_ycsb
arcsrc10_ycsb
arcsrc100_ycsb
arcsrc1k_ycsb

arcsrc_tpcc
arcsrc10_tpcc
arcsrc100_tpcc
arcsrc1k_tpcc


