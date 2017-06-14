# Apache Spark Workflow

This is an example Pegasus workflow for deploying [Apache Spark](http://spark.apache.org/) + [Apache Hadoop](http://hadoop.apache.org/) (Yarn) on the fly (as a workflow job), and run a simple word count program.

<img src="docs/workflow.png?raw=true" width="60%" />

Requirements
------------
This workflow assumes that SSH connections without password from the submit host to workers are enabled.

The workflow input files include:
- `hosts.txt`: A list of hosts for deploying the Apache Hadoop + Spark system. The first line of the file should contain the **master** host, and the remaining lines a set of **slave** hosts.
- `sample.txt`: A simple text file to be used by the word count program.

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
