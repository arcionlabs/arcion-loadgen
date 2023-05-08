#!/usr/bin/env bash

  per-table-config:
  - catalog: "${SRCDB_DB}"
    schema: ${SRCDB_SCHEMA}   
    tables:
      THEUSERTABLE:
        split-key: YCSB_KEY
        split-method: RANGE # must be all caps
        extraction-priority: 1
        split-hints:
          row-count-estimate:  20000000
          split-key-min-value: 0
          split-key-max-value: 19999999