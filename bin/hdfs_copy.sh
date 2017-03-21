#!/bin/bash

source $HOME/.bashrc

FILENAME=`basename $1`

echo "Copying $1 to HDFS"
hdfs dfs -copyFromLocal $1 /$FILENAME
