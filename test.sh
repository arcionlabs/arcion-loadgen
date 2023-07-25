#!/usr/bin/env bash

declare -A SRCDB_PROFILE_DICT=([1]=1 [2]=2)

declare -p SRCDB_PROFILE_DICT

func1() {
  declare -p SRCDB_PROFILE_DICT
}

func1
