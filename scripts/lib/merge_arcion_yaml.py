#!/usr/bin/env python3

from typing import Optional
from pydantic import BaseModel
from upath import UPath as Path
# from pathlibfs import Path
from expandvars import expandvars
import jinja2
import click
# pyyaml cannot handle the arcion mapper.  
from ruamel.yaml import YAML
import json
from jsonmerge import Merger
import subprocess
import sys

import logging
logging.basicConfig(level=logging.WARNING)

ruamel=YAML(typ='safe')     # default, if not specfied, is 'rt' (round-trip)
yaml=YAML()                 # default, if not specfied, is 'rt' (round-trip)

schema = {
    "patternProperties": {
        # mapper
        "rules" : {
            "type" : "object",
            "properties": {
                "source": {
                    "mergeStrategy": "objectMerge"        
                },
            },
        },    
        # filter
        "allow": {
            "type": "array",
            "mergeStrategy": "arrayMergeById",
            "mergeOptions": {"idRef": ["catalog","schema"] },
            "properties": {
                "allow": {
                    "mergeStrategy": "merge"        
                },
                "block": {
                    "mergeStrategy": "merge"        
                }           
            }
        },
        # extractor and applier
        "snapshot|realtime|delta-snapshot": {
            "properties": {
                "per-table-config": {            
                    "type": "array",
                    "mergeStrategy": "arrayMergeById",
                    "mergeOptions": {"idRef": ["catalog","schema"] },
                    "properties": {
                        "tables": {
                            "mergeStrategy": "merge"        
                        },
                    },         
                }
            }
        },
        # transformation
        "per-table-config": {
            "type": "array",
            "mergeStrategy": "arrayMergeById",
            "mergeOptions": {"idRef": ["catalog","schema"] },
            "properties": {
                "tables": {
                    "mergeStrategy": "merge"        
                },
            },         
        }
    }
}

merger = Merger(schema)

jjenv = jinja2.Environment(extensions=['jinja2_getenv_extension.GetenvExtension'])

def mergeFromString(source_json:json, target_json:json={} ):
    target_json=merger.merge(target_json, source_json)

def mergeFromFiles(filenames:list[Path],target_json:dict={},echo=False) -> str:
    """Merge YAML Arcion Extractor YAMLs property group by [`catalog`, `schema`]."""
    for file in filenames:
        string = file.open().read()
        # jinja2 template (new standards)
        # order is important as heredoc strips out quotes
        cp = jjenv.from_string(string)
        cp = cp.render()
        # bash template (for backward compat)
        cp = heredocString(cp)
        cp=cp.stdout
        # convert to YAML
        yaml_string=ruamel.load(cp)
        if yaml_string:
            target_json=merger.merge(target_json, yaml_string)

    if echo:
        # don't print on empty json
        if bool(target_json):
            yaml.dump(target_json, sys.stdout)
    return(target_json)

@click.group()
def cli():
    pass

def heredocString(string:str,echo:bool=False) -> subprocess.CompletedProcess:
    """heredoc a string
        WARNING: quote is stripped off
    """
    cp=subprocess.run(f"""cat <<EOF_EOF_EOF\n{string}\nEOF_EOF_EOF""",
        executable='bash',
        shell=True,
        capture_output=True,
        text=True
        )
    if echo:
        print(cp.stdout)
    return(cp)    

def heredocPath(path:Path,echo:bool) -> subprocess.CompletedProcess:
    """read path and run heredoc against it"""
    cp=subprocess.run(f"""cat <(echo "cat<<EOF_EOF_EOF") {path.path} <(echo "EOF_EOF_EOF") | bash""",
        executable='bash',
        shell=True,
        capture_output=True,
        text=True
        )
    if echo:
        print(cp.stdout)
    return(cp)

@click.command("hdfile")
@click.argument('filename')
@click.option('-p', 'echo', default=True, type=bool,show_default=True)
def heredocFile(filename:str, echo:bool) -> subprocess.CompletedProcess:
    """heredoc a file"""
    path = Path(filename)
    return(heredocPath(path,echo))

def mergeYamls(yamls:list[str], basedir:str="", echo:bool=True, suffix=".yaml") -> str:
    """Merge Arcion bash heredoc template YAML files"""
    FILTER_FILES=[]
    for filterspec in yamls:
        filterspec+=suffix
        filename=Path(expandvars(basedir)).joinpath(expandvars(f"{filterspec}"))
        logging.info(filename)
        if filename.is_file():
            FILTER_FILES.append(filename)
        else:
            logging.info(f"{filterspec} not found in '{basedir}' dir")
    if FILTER_FILES: 
        mergeFromFiles(FILTER_FILES,echo=echo)

@click.command("filter")
@click.option('--basedir',default=".",show_default=True)
@click.option('--suffix',default=".yaml",show_default=True)
@click.option('-p', '--echo', 'echo', default=True, type=bool,show_default=True)
@click.argument('yamls',nargs=-1)
def mergeFilter(basedir:str,suffix:str,echo:bool,yamls:list[str]):
    mergeYamls(yamls,basedir=basedir,echo=echo,suffix=suffix)

map_replmodes={
    'snapshot':['snapshot'],
    'real-time':['realtime'],
    'realtime':['realtime'],
    'full':['snapshot','realtime'],
    'delta-snapshot':['delta-snapshot'],
}

@click.command("app")
@click.option('--basedir',default=".",show_default=True)
@click.option('--config',type=click.Choice(['applier', 'extractor', 'filter']),show_default=True, required=True)
@click.option('--replmode', type=click.Choice(["snapshot","real-time","real-time","full","delta-snapshot"]),show_default=True, required=True)
@click.option('--baseyaml',type=str, required=False)
@click.option('--suffix',default=".yaml",show_default=True)
@click.option('-p', '--echo', 'echo', default=True, type=bool,show_default=True)
@click.argument('files',nargs=-1)
def mergeApp(files:list[str], 
             baseyaml:str=None,
             basedir:str=None,config:str=None, replmode:str="", suffix:str=None, echo:bool=None):
    """Merge files based on rules of basedir/config.replmode.yaml"""
    yamls=[]
    replmodes = map_replmodes[replmode]
    if baseyaml:
        yamls.append(f"{baseyaml}")
    for y in files:
        for replmode in replmodes:
            file=f"{basedir}/{y}/{config}.{replmode}{suffix}"
            yamls.append(file)
    mergeYamls(yamls, echo=echo, basedir="", suffix="" )

@click.command("files")
@click.option('-p', '--echo', 'echo', default=True, type=bool,show_default=True)
@click.argument('yamls',nargs=-1)
def mergeFiles(yamls:list[str],
             echo:bool):
    """Merge files into a single YAML"""
    mergeYamls(yamls, echo=echo, basedir="", suffix="" )

if __name__ == '__main__':

    cli.add_command(heredocFile)
    cli.add_command(mergeFiles)
    cli.add_command(mergeApp)
    cli.add_command(mergeFilter)
    cli()