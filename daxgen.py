#!/usr/bin/env python

import os
import pwd
import sys
import time
from Pegasus.DAX3 import *

# The name of the DAX file is the first argument
if len(sys.argv) != 2:
        sys.stderr.write("Usage: %s DAXFILE\n" % (sys.argv[0]))
        sys.exit(1)
daxfile = sys.argv[1]

# Create an abstract dag
dax = ADAG("spark-workflow")

# Add transformations (executables)
base_dir = os.getcwd()

for tname in ["install-spark", "hdfs-copy", "word-count", "remove-spark"]:
    t = Transformation(tname)
    e = Executable(tname, arch = "x86_64", installed = True)
    e.addPFN(PFN("file://" + base_dir + "/bin/" + tname + ".sh", "local"))
    t.uses(e)
    dax.addExecutable(e)
    dax.addTransformation(t)

# Input Files
hadoop_tgz = File("hadoop.tgz")
spark_tgz = File("spark.tgz")
hosts = File("hosts.txt")
sample = File("sample.txt")

# The setup job (Hadoop + Yarn + Spark)
setup_job = Job("install-spark")
setup_job.addArguments(hadoop_tgz, spark_tgz, hosts)
setup_job.uses(hadoop_tgz, link=Link.INPUT)
setup_job.uses(spark_tgz, link=Link.INPUT)
setup_job.uses(hosts, link=Link.INPUT)
dax.addJob(setup_job)

# Copying sample data to HDFS
copy_job = Job("hdfs-copy")
copy_job.addArguments(sample)
copy_job.uses(sample, link=Link.INPUT)
dax.addJob(copy_job)
dax.depends(copy_job, setup_job)

# Word count job
wc_job = Job("word-count")
wc_job.addArguments(sample.name)
dax.addJob(wc_job)
dax.depends(wc_job, copy_job)

# Remove job
rm_job = Job("remove-spark")
rm_job.addArguments(hosts)
rm_job.uses(hosts, link=Link.INPUT)
dax.addJob(rm_job)
dax.depends(rm_job, wc_job)

f = open(daxfile, "w")
dax.writeXML(f)
f.close()
print "Generated dax %s" %daxfile
