#!/usr/bin/env bash

jdbc_cli() { 
  ${JSQSH_DIR}/*/bin/jsqsh ${1} --driver="${jsqsh_driver}" --user="${db_user}" --password="${db_pw}" --server="${db_host}" --port="${db_port}" --database="${db_user}" 2>&1
}

jdbc_cli_src() {
  local db_host="${SRCDB_HOST}"  
  local db_user="${SRCDB_ARC_USER}"
  local db_pw="${SRCDB_ARC_PW}"
  local db_port="${SRCDB_PORT}"
  local jsqsh_driver="${SRCDB_JSQSH_DRIVER}"

  jdbc_cli "$*"
}

jdbc_cli_dst() {
  local db_host="${DSTDB_HOST}"  
  local db_user="${DSTDB_ARC_USER}"
  local db_pw="${DSTDB_ARC_PW}"
  local db_port="${DSTDB_PORT}"
  local jsqsh_driver="${DSTDB_JSQSH_DRIVER}"

  jdbc_cli "$*"
}
