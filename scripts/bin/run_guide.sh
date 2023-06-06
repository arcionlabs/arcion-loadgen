#!/usr/bin/env bash

# create a markdown report

# $1=dir name where the cfg is at
arcion_metadata() {
   f=$1

   # Elapsed time from the end of the file
   elapsed_time=$(tac $ROOT_DIR/$f/arcion.log | awk -F'[: ]' '/Elapsed time/ {print $4 ":" $5 ":" $6 ; exit}')

   # version from the tracelog
   # skip the first 2 char of the string
   # the first should have the 
   readarray -d '-' -t run_id_array <<< "${f:2}"
   # script error where trace.log was not saved correctly
   if [ -f "$ROOT_DIR/${run_id_array[0]}/trace.log" ]; then
      arcion_version=$(awk 'NR == 5 {print $NF; exit}' $ROOT_DIR/${run_id_array[0]}/trace.log)
   else
      arcion_version="?"
   fi
}


yaml=(
    src.yaml \
    dst.yaml \
    src_extractor.yaml \
    src_filter.yaml \
    dst_mapper.yaml \
    dst_applier.yaml \
    general.yaml) 

init=(
    src.init.root.* \
    src.init.user.* \
    dst.init.root.* \
    dst.init.user.* \
    )

   ROOT_DIR=$(dirname $(pwd) )
   RUN_DIR=$( basename $(pwd))

   # Elapsed time from the end of the file
   elapsed_time=$(tac $ROOT_DIR/$f/arcion.log | awk -F'[: ]' '/Elapsed time/ {print $4 ":" $5 ":" $6 ; exit}')

   # version from the tracelog
   # skip the first 2 char of the string
   # the first should have the 
   readarray -d '-' -t run_id_array <<< "${RUN_DIR:2}"
   # script error where trace.log was not saved correctly
   if [ -f "$ROOT_DIR/${run_id_array[0]}/trace.log" ]; then
      arcion_version=$(awk 'NR == 5 {print $NF; exit}' $ROOT_DIR/${run_id_array[0]}/trace.log)
   else
      arcion_version="?"
   fi
   source_host=${run_id_array[2]}
   target_host=${run_id_array[3]}
   repl_mode=${run_id_array[4]}

   echo $source_host
   echo $target_host
   echo $repl_mode

output_md="guide.md"

cat <<EOF > ${output_md}
$source_host $target_host $repl_mode 
EOF


cat <<EOF >> ${output_md}
# Setup for data source and target.  
EOF

for pattern in "${init[@]}"; do
    # case insensitive name
    # exclude anyting that ends with .log
    for f in $( find -iname "$pattern" \( ! -iname "*.log" \) -type f); do
        file_extension="${f##*.}"
        echo "## $f" >> ${output_md}
        echo '```'$file_extension >> ${output_md}
        cat $f |  \
            sed -e 's/\(username\:\).*$/\1 ********/i' \
                -e 's/\(password\:\).*$/\1 ********/i' \
                -e 's/\(secret-key\:\).*$/\1 ********/i' \
                 -e 's/\(key-id\:\).*$/\1 ********/i' >> ${output_md}
        echo '' >> ${output_md}
        echo '```' >> ${output_md}
    done
done

cat <<EOF >> ${output_md}
# Arcion YAML files for source and target.  
EOF

for pattern in "${yaml[@]}"; do
    # case insensitive name
    # exclude anyting that ends with .log
    for f in $( find -iname "$pattern" \( ! -iname "*.log" \) -type f); do

        echo "## $f" >> ${output_md}
        echo '```yaml' >> ${output_md}
        cat $f |  \
            sed -e 's/\(username\:\).*$/\1 ********/i' \
                -e 's/\(password\:\).*$/\1 ********/i' \
                -e 's/\(secret-key\:\).*$/\1 ********/i' \
                 -e 's/\(key-id\:\).*$/\1 ********/i' >> ${output_md}
        echo '' >> ${output_md}
        echo '```' >> ${output_md}
    done
done

cat <<EOF >> ${output_md}
# Arcion command.  
EOF

   readarray -d '-' -t run_id_array <<< "${RUN_DIR}"
   echo "${run_id_array[@]}" >&2
   # script error where trace.log was not saved correctly
   if [ -f "$ROOT_DIR/${run_id_array[0]}/trace.log" ]; then
      arcion_cmd=$(awk 'NR == 3 {print $0; exit}' $ROOT_DIR/${run_id_array[0]}/trace.log | \
        sed 's/.*Command : //' | \
        sed "s/$RUN_DIR//" | \
        sed "s|$ROOT_DIR/||" \
        )
   else
      arcion_cmd="?"
   fi

    echo '`'"${arcion_cmd}"'`' >>${output_md}     
    echo '' >> ${output_md}

