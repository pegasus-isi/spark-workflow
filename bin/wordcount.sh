#!/bin/bash

source $HOME/.bashrc

echo "Starting Yarn"
$HOME/apps-workflow/hadoop/sbin/start-yarn.sh

echo "Leaving HDFS safe mode..."
hdfs dfsadmin -safemode leave 

echo "Launching application"
$HOME/apps-workflow/spark/bin/spark-submit --master yarn --deploy-mode cluster --driver-memory 1g --executor-memory 1g --executor-cores 1 --num-executors 2 file://$HOME/apps-workflow/spark/examples/src/main/python/wordcount.py /$1
