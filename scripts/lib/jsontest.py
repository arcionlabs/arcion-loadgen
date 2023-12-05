#!/usr/bin/env python3

import jsonschema
from ruamel.yaml import YAML
from ruamel.yaml.main import \
    round_trip_load as yaml_load, \
    round_trip_dump as yaml_dump

ruamel=YAML(typ='safe')   # default, if not specfied, is 'rt' (round-trip)

schema = {
    "patternProperties": {
        # mapper
        "rules": {
            "type" : "array",
            "properties": {
                "source": {
                    "mergeStrategy": "objectMerge"        
                },
            },
        },
    },
} 

map1_str="""
rules:
  [ this, that ]:
    source:
    - [ that,this ]
"""
map2_str="""
rules:
  [ this1, that1 ]:
    source:
    - [ that,this ]
"""

map1 = ruamel.load(map1_str)
map2 = ruamel.load(map2_str)

from jsonschema import validate
validate(map,schema)

from jsonmerge import Merger
merger = Merger(schema)
merger.merge(map1,map2)