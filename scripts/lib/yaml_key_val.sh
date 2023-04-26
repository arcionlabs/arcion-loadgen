#!/bin/bin/env bash

# scrap key:value out of YAML file and return as associate array

# TODO: I am sture there is better way, just don't know jq well enought to make this a one line
yaml_key_val() {
  local file=$1
  local pattern=$2

  # remove lead and trailing spaces
  yq -r " .. | .${pattern}? // empty" $file

}