#!/usr/bin/env python3

import click
import yaml
import json
from jsonmerge import Merger

schema = {
    "properties": {
        "allow": {
            "type": "array",
            "mergeStrategy": "arrayMergeById",
            "mergeOptions": {"idRef": ["catalog","schema"] },
            "properties": {
                "allow": {
                    "mergeStrategy": "merge"        
                }
            }
        }
    }
}

@click.command()
@click.argument('filenames',nargs=-1)
def mergeArcionFilter(filenames:list[str]) -> str:
    """Merge YAML files `.allow` property group by [`catalog`, `schema`]."""
    target_json={}
    merger = Merger(schema)
    for file in filenames:
        yaml_file=yaml.safe_load(open(file))
        target_json=merger.merge(target_json, yaml_file)
    print(yaml.dump(target_json))

if __name__ == '__main__':
    mergeArcionFilter()