# Apache Spark Workflow

This is an example Pegasus workflow for deploying [Apache Spark](http://spark.apache.org/) + [Apache Hadoop](http://hadoop.apache.org/) (Yarn) on the fly (as a workflow job), and run a simple word count program.

Requirements
------------
This workflow assumes that SSH connections without password from the submit host to workers are enabled.

Generating a Workflow
---------------------
```
$ ./generate_dax.sh spark.dax
```

Running a Workflow
-------------------
```
$ ./plan_dax.sh spark.dax
```
