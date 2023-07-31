#!/bin/bin/env bash

# scrap key:value out of YAML file and return as associate array

# TODO: I am sture there is better way, just don't know jq well enought to make this a one line
# $1=yaml file
# $2=key to look for
yaml_key_val() {
  local file=$1
  local pattern=$2

  # remove lead and trailing spaces
  yq -r " .. | .${pattern}? // empty" $file

}

# try to figure out the host
# $1=yaml file
#
# kinds of host
# 1  host: xxx
# 2  conn-url: xxx
# 3  endpoint:
#     service-endpint: xxx
# 4  brokers:
#     somename:
#       host: xxx
get_host_from_yaml() {
   local yamlfile=$1
   local hostname

   # regular host name
   hostname=$(cat $yamlfile | yq -r '.host // ""')

   # url
   # remove http://id:pass@minio-v230602-1:9000 http and : at the end
   if [ -z "$hostname" ]; then
      hostname=$(cat $yamlfile | yq -r '."conn-url" // ""' | \
         sed -e 's|^[^/]*//||' -e 's|^.*@||' -e 's|/.*$||' -e 's|\:.*$||')
   fi

   # kafka
   if [ -z "$hostname" ]; then
      hostname=$(cat $yamlfile | yq -r '.brokers[].host // ""' 2>/dev/null)
   fi

   # s3
   # remove http://minio-v230602-1:9000 http and : at the end
   if [ -z "$hostname" ]; then
      hostname=$(cat $yamlfile | yq -r '.endpoint."service-endpoint" // ""' | \
         sed -e 's|^[^/]*//||' -e 's|^.*@||' -e 's|/.*$||' -e 's|\:.*$||')
   fi
      
   echo $hostname
}
