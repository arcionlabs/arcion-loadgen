#!/usr/bin/env python3

from typing import Optional
from pydantic import BaseModel
from upath import UPath as Path
# from pathlibfs import Path
from expandvars import expandvars
import jinja2
import click
import yaml
import json
from jsonmerge import Merger
import subprocess

import logging
logging.basicConfig(level=logging.INFO)

schema = {
    "patternProperties": {
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
        # bash template (for backward compat)
        cp = heredocString(cp.render())
        # convert to YAML
        yaml_string=yaml.safe_load(cp.stdout)
        # merge YAML
        target_json=merger.merge(target_json, yaml_string)

    if echo:
        print(yaml.dump(target_json,indent=2))    
    return(target_json)

@click.group()
def cli():
    pass

def heredocString(string:str,echo:bool=False) -> subprocess.CompletedProcess:
    """heredoc a string"""
    cp=subprocess.run(f"""echo -e '#!/usr/bin/env bash\ncat << EOF_EOF_EOF\n{string}\nEOF_EOF_EOF' | bash""",
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
    string = path.open().read()
    return(heredocString(string,echo))

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
            logging.warning(f"{filterspec} not found in {basedir} dir")
            return(1)
    if FILTER_FILES: 
        mergeFromFiles(FILTER_FILES,echo=echo)

@click.command("filter")
@click.option('--basedir',default=".",show_default=True)
@click.option('--suffix',default=".yaml",show_default=True)
@click.option('-p', '--echo', 'echo', default=True, type=bool,show_default=True)
@click.argument('yamls',nargs=-1)
def mergeFilter(basedir:str,suffix:str,echo:bool,yamls:list[str]):
    mergeYamls(yamls,basedir=basedir,echo=echo,suffix=suffix)

@click.command("app")
@click.option('--basedir',default=".",show_default=True)
@click.option('--config',show_default=True,type=click.Choice(['applier', 'extractor']))
@click.option('--replmode',show_default=True,type=click.Choice(["snapshot","realtime","full","delta-snapshot"]))
@click.option('--suffix',default=".yaml",show_default=True)
@click.option('-p', '--echo', 'echo', default=True, type=bool,show_default=True)
@click.argument('yamls',nargs=-1)
def mergeAny(basedir:str,config:str, replmode:str, suffix:str,echo:bool,yamls:list[str]):
    for y in yamls:
        pass
    mergeYamls(yamls, echo=echo, basedir="",suffix=suffix )

@click.command("any")
@click.option('--basedir',default=".",show_default=True)
@click.option('--basefile',default="extractor.snapshot.yaml",show_default=True)
@click.option('-p', '--echo', 'echo', default=True, type=bool,show_default=True)
@click.argument('dirs',nargs=-1)
def mergeExtractor(basedir:str,basefile:str,echo:bool,dirs:list[str]):
    full_dirs:list[str]=[]
    for d in dirs:
        full_dirs.append(f'{d}/{basefile}')
    print(full_dirs)
    mergeYamls(basedir,echo,full_dirs)

if __name__ == '__main__':

    cli.add_command(heredocFile)
    cli.add_command(mergeAny)
    cli.add_command(mergeFilter)
    cli.add_command(mergeExtractor)
    cli()