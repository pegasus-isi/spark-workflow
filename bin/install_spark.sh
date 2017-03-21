#!/bin/bash

HADOOP_TGZ=$1
SPARK_TGZ=$2
HOSTS=$3

echo "Running on: $PWD"

## READING HOSTS
declare -a hosts
readarray -t hosts < $3

let i=0
while (( ${#hosts[@]} > i )); do
    ((i++))
done

echo "Hosts: "
echo "  Master: ${hosts[0]}"
echo "  # Workers: $((i - 1))"
echo ""



## INSTALL HADOOP

echo "Installing Hadoop..."

HADOOP_PREFIX=$HOME/apps-workflow/hadoop
echo "  Hadoop will be installed and configured in: $HADOOP_PREFIX"

mkdir -p $HOME/apps-workflow/ >&2

echo "  Copying $HADOOP_TGZ to workers and uncompressing it"
let i=1
while (( ${#hosts[@]} > i )); do
    ssh ${hosts[i]} mkdir -p $HOME/apps-workflow/ >&2
    scp $HADOOP_TGZ ${hosts[i]}:$HOME/apps-workflow/hadoop.tgz >&2
    ssh ${hosts[i]} "cd $HOME/apps-workflow/; tar -zxf hadoop.tgz" >&2
    ssh ${hosts[i]} rm -rf $HOME/apps-workflow/hadoop.tgz >&2
    ssh ${hosts[i++]} mv $HOME/apps-workflow/hadoop-* $HOME/apps-workflow/hadoop >&2
done

echo "  Uncompressing Hadoop: $HADOOP_TGZ"
tar -zxf $HADOOP_TGZ
rm -rf $HADOOP_TGZ
mv hadoop*  $HADOOP_PREFIX


# add hadoop environment variables to .bashrc
echo "  Adding Hadoop environment variables to .bashrc"
let i=0
while (( ${#hosts[@]} > i )); do
    ssh ${hosts[i++]} cat >> $HOME/.bashrc << EOL

# hadoop variables
export HADOOP_PREFIX=$HADOOP_PREFIX
export HADOOP_HOME=\$HADOOP_PREFIX
export HADOOP_COMMON_HOME=\$HADOOP_PREFIX
export HADOOP_CONF_DIR=\$HADOOP_PREFIX/etc/hadoop
export HADOOP_HDFS_HOME=\$HADOOP_PREFIX
export HADOOP_MAPRED_HOME=\$HADOOP_PREFIX
export HADOOP_YARN_HOME=\$HADOOP_PREFIX
export PATH=\$PATH:\$HADOOP_PREFIX/sbin:\$HADOOP_PREFIX/bin

EOL
done


# set up NameNode URI
echo "  Setting up NameNode URI: $HADOOP_PREFIX/etc/hadoop/core-site.xml"
cat > $HADOOP_PREFIX/etc/hadoop/core-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
    <name>fs.defaultFS</name>
    <value>hdfs://submit:9000/</value>
</property>
</configuration>
EOL

# Create HDFS DataNode and NameNode data dirs
echo "  Creating HDFS DataNode and NameNode data dirs"
mkdir -p $HOME/namenode # only on master
mkdir -p $HOME/datanode
let i=1
while (( ${#hosts[@]} > i )); do
    ssh ${hosts[i++]} mkdir -p $HOME/datanode >&2
done


echo "  Configuring $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml"
cat > $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>dfs.replication</name>
  <value>3</value>
</property>
<property>
  <name>dfs.permissions</name>
  <value>false</value>
</property>
<property>
   <name>dfs.datanode.data.dir</name>
   <value>$HOME/datanode</value>
</property>
</configuration>
EOL

echo "  Copying hadoop configuration files to workers"
let i=1
while (( ${#hosts[@]} > i )); do
    scp -p $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml ${hosts[i]}:$HADOOP_PREFIX/etc/hadoop/hdfs-site.xml >&2
    scp -p $HADOOP_PREFIX/etc/hadoop/core-site.xml ${hosts[i++]}:$HADOOP_PREFIX/etc/hadoop/core-site.xml >&2
done



cat > $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml << EOL
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<property>
  <name>dfs.replication</name>
  <value>3</value>
</property>
<property>
  <name>dfs.permissions</name>
  <value>false</value>
</property>
<property>
   <name>dfs.datanode.data.dir</name>
   <value>$HOME/datanode</value>
</property>
<property>
   <name>dfs.namenode.data.dir</name>
   <value>$HOME/namenode</value>
</property>
</configuration>
EOL


echo "  Configuring $HADOOP_PREFIX/etc/hadoop/mapred-site.xml"
cat > $HADOOP_PREFIX/etc/hadoop/mapred-site.xml << EOL
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
 <property>
  <name>mapreduce.framework.name</name>
   <value>yarn</value> <!-- and not local (!) -->
 </property>
</configuration>
EOL


# setup ResourceManager and NodeManagers
echo "  Setting up ResourceManager and NodeManagers"
let i=1
while (( ${#hosts[@]} > i )); do
cat > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml << EOL
<?xml version="1.0"?>
<configuration>
<property>
        <name>yarn.resourcemanager.hostname</name>
        <value>${hosts[0]}</value>
</property>
<property>
        <name>yarn.nodemanager.hostname</name>
        <value>${hosts[i]}</value>
</property>
<property>
  <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
</property>
</configuration>
EOL
scp -p $HADOOP_PREFIX/etc/hadoop/yarn-site.xml ${hosts[i++]}:$HADOOP_PREFIX/etc/hadoop/yarn-site.xml >&2
done

cat > $HADOOP_PREFIX/etc/hadoop/yarn-site.xml << EOL
<?xml version="1.0"?>
<configuration>
<property>
	<name>yarn.resourcemanager.hostname</name>
        <value>${hosts[0]}</value>
</property>
<property>
	<name>yarn.nodemanager.hostname</name>
        <value>${hosts[0]}</value>
</property>
<property>
  <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
</property>
</configuration>
EOL


# Add list of slaves on master
echo "  Adding list of slaves on master"
cat > $HADOOP_PREFIX/etc/hadoop/slaves << EOL
submit
worker1
worker2
EOL


# Format NameNode
echo "  Formating NameNode"
source $HOME/.bashrc >&2
hdfs namenode -format -force >&2

WORKDIR=$PWD

cd $HOME/apps-workflow

echo "  Starting HDFS"
nohup start-dfs.sh &
disown -h
sleep 30

echo "  Starting Hadoop + Yarn"
nohup start-yarn.sh &
jobs
disown -h
sleep 30
hdfs dfsadmin -safemode leave >&2

cd $WORKDIR

echo "Hadoop has been successfully configured!"
echo ""




## INSTALL SPARK
echo "Installing Spark..."

SPARK_PREFIX=$HOME/apps-workflow/spark
echo "  Spark will be installed and configured in: $SPARK_PREFIX"

echo "  Copying $SPARK_TGZ to workers and uncompressing it"
let i=1
while (( ${#hosts[@]} > i )); do
    scp -r -p $SPARK_TGZ ${hosts[i]}:$HOME/apps-workflow/spark.tgz >&2
    ssh ${hosts[i]} "cd $HOME/apps-workflow; tar -zxf spark.tgz" >&2
    ssh ${hosts[i]} rm -rf $HOME/apps-workflow/spark.tgz >&2
    ssh ${hosts[i++]} mv $HOME/apps-workflow/spark-* $HOME/apps-workflow/spark >&2
done

echo "  Uncompressing Spark: $SPARK_TGZ"
tar -zxf $SPARK_TGZ
rm -rf $SPARK_TGZ
mv spark-*  $SPARK_PREFIX


echo "  Configuring $SPARK_PREFIX/conf/spark-env.sh"
cat >> $SPARK_PREFIX/conf/spark-env.sh << EOL
SPARK_JAVA_OPTS=-Dspark.driver.port=53411
HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop
SPARK_MASTER_IP=${hosts[0]}
EOL

echo "  Configuring $SPARK_PREFIX/conf/spark-defaults.conf"
cat >> $SPARK_PREFIX/conf/spark-defaults.conf << EOL
spark.master            spark://${hosts[0]}:7077
spark.serializer        org.apache.spark.serializer.KryoSerializer
EOL

echo "  Copying Spark configuration files to workers"
let i=1
while (( ${#hosts[@]} > i )); do
    scp -p $SPARK_PREFIX/conf/spark-env.sh ${hosts[i]}:$SPARK_PREFIX/conf/spark-env.sh >&2
    scp -p $SPARK_PREFIX/conf/spark-defaults.conf ${hosts[i]}:$SPARK_PREFIX/conf/spark-defaults.conf >&2
    ssh ${hosts[i++]} mkdir -p /tmp/spark-events >&2
done

mkdir -p /tmp/spark-events >&2


echo "  Configuring $SPARK_PREFIX/conf/slaves"
cat $3 >> $SPARK_PREFIX/conf/slaves

echo "  Starting Spark"
nohup $SPARK_PREFIX/sbin/start-master.sh &
nohup $SPARK_PREFIX/sbin/start-slaves.sh &
jobs
disown -h
sleep 30

echo "Spark has been successfully configured!"
echo ""
