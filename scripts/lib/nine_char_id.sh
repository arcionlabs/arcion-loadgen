#!/usr/bin/env bash

nine_char_id() {
    printf "%09x\n" "$(( $(date +%s%N) / 100000000 ))"
}

epoch_10th_sec() {
    printf "%d\n" "$(( $(date +%s%N) / 100000000 ))"
}

# 2023-06-11 22:09:47.095
nine_char_trace_log_date() {
    local DATE=${1}
    printf "%09x\n" "$(( $(date -d "$DATE" +'%s%N') / 100000000 ))"
}