#!/usr/bin/env bash

nine_char_id() {
    printf "%09x\n" "$(( $(date +%s%N) / 100000000 ))"
}