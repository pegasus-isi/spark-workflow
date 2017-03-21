#!/bin/bash

HOSTS=$1

## READING HOSTS
declare -a hosts
readarray -t hosts < $1

let i=0
while (( ${#hosts[@]} > i )); do
    ((i++))
done

echo "Hosts: "
echo "  Master: ${hosts[0]}"
echo "  # Workers: $((i - 1))"
echo ""


HADOOP_PREFIX=$HOME/apps-workflow/hadoop
SPARK_PREFIX=$HOME/apps-workflow/spark


echo "Stopping Spark..."
$SPARK_PREFIX/sbin/stop-all.sh >&2

echo "Stopping Hadoop..."
$HADOOP_PREFIX/sbin/stop-yarn.sh >&2
$HADOOP_PREFIX/sbin/stop-dfs.sh >&2


echo "Removing Spark and Hadoop..."
let i=0
while (( ${#hosts[@]} > i )); do
    ssh ${hosts[i]} rm -rf $SPARK_PREFIX 
    ssh ${hosts[i]} rm -rf $HADOOP_PREFIX 
    ssh ${hosts[i]} rm -rf /tmp/spark-events 
    ssh ${hosts[i]} rm -rf $HOME/datanode 
    ssh ${hosts[i]} rm -rf /tmp/hadoop-hadoop 
    ssh ${hosts[i]} rm -rf /tmp/hsperfdata_hadoop 
    ssh ${hosts[i++]} rm -rf $HOME/.sparkStaging
done
rm -rf $HOME/namenode


echo "Spark and Hadoop have been successfully removed!"
echo ""
