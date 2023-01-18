#!/usr/bin/env bash

pushd /jobs
PS3='Please enter the source/target: '
options=( $(find * -type d) )

select JOB in "${options[@]}"
do
    if [ -d "$JOB" ]; then
        break
    else
        echo "invalid option"
    fi
done
popd

DIR=/tmp/$JOB
pushd /arcion/replicant-cli
cat replicant.lic
mkdir -p $DIR
for f in /jobs/$JOB/*; do 
  echo $f
  cat $f | envsubst > $DIR/$(basename $f) 
done

./bin/replicant full ${DIR}/src_1.yaml ${DIR}/dst_1.yaml \
--filter ${DIR}/src_1_filter.yaml \
--extractor ${DIR}/src_1_extractor.yaml \
--applier ${DIR}/dst_1_applier.yaml \
--replace-existing \
--overwrite \
--id 2
popd
