#!/usr/bin/env python3

import click
import re
from upath import UPath as Path

arcion_configs={
    "dst": {"target":"dst.yaml"},
    "applier": {"target":"dst_applier.yaml",},
    "mapper": {"target":"dst_mapper.yaml"},
    "src": {"target":"src.yaml"},
    "extractor": {"target":"src_extractor.yaml"},
    "filter": {"target":"src_filter.yaml"},
    "general": {"target":"general.yaml"},    
}

@click.command()
@click.option('--suffix',default="",show_default=True, required=False)
@click.option('--diryamls',default=[[".","*.yaml"]],nargs=2, multiple=True, show_default=True, required=True)
def merge_yamls(diryamls:str=".",suffix:str=""):
    """YAML merge from diryamls
        diryamls=dir filename[,filename]
    """
    for dir_yamls in diryamls:
        dir=dir_yamls[0]
        yamls=dir_yamls[1].split(",")
        for yaml in yamls:
            yamlpath=Path(dir).joinpath(f"{yaml}{suffix}")
            if yamlpath.is_file():
                print(yamlpath.open().read())          

if __name__ == '__main__':
    merge_yamls()
