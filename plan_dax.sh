#!/bin/bash

DIR=$(cd $(dirname $0) && pwd)

if [ $# -ne 1 ]; then
    echo "Usage: $0 DAXFILE"
    exit 1
fi

cat > rc.txt << EOF
hadoop.tgz http://apache.parentingamerica.com/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz site="local"
spark.tgz http://d3kbcqa49mib13.cloudfront.net/spark-2.1.0-bin-hadoop2.7.tgz site="local"
hosts.txt file:///$DIR/input/hosts.txt site="local"
sample.txt file:///$DIR/input/sample.txt site="local"
EOF

DAXFILE=$1

# This command tells Pegasus to plan the workflow contained in 
# dax file passed as an argument. The planned workflow will be stored
# in the "submit" directory. The execution # site is "".
# --input-dir tells Pegasus where to find workflow input files.
# --output-dir tells Pegasus where to place workflow output files.
pegasus-plan --conf pegasus.properties \
    --dax $DAXFILE \
    --dir $DIR/submit \
    --input-dir $DIR/input \
    --output-dir $DIR/output \
    --cleanup leaf \
    --force \
    --sites local \
    --submit
