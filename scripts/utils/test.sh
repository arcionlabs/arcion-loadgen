#!/usr/bin/env bash

declare -A animals
export animals
animals[duck]="quack"
declare -p animals
