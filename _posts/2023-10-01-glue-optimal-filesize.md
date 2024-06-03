---
title: "Fine-Tuning Glue Export File Size for Athena Queries"
page_title: "Fine-Tuning Glue Export File Size for Athena Queries"
excerpt: "Exploring different strategies for fine-tuning the output file size 
in AWS Glue and consolidating small files during post-processing. By 
implementing these techniques, you'll not only enhance the efficiency of 
Athena queries but also significantly reduce the cost associated with 
querying large datasets."
date: October 1, 2023
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: October 1, 2023
og_image: /assets/images/posts/glue-export-file-size/header.jpg
---

{% include image.html
    src="/assets/images/posts/glue-export-file-size/header.jpg"
    alt="glue-export-file-size"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

## Introduction

If you are building datalakes on AWS, most likely you are using AWS Athena to 
provide your organization a way to analyze vast amounts of data residing in 
Amazon S3 with lighthing-fast speed and efficiency.

However, the performance of Athena queries is significantly impacted by the 
size and organization of the underlying data files. Small files can lead to 
increased latency and higher costs due to the nature of how Athena processes 
data.

As we already know, Athena is charging us based on the amount of data scanned. 
Of course, there are additional costs. If we are scanning data which resides in 
S3, we are charged standard S3 rates for storage, requests, and data transfers. 

We can save up to 90% per query and get better performance by compressing, 
partitioning, and converting the data into columnar formats such as Parquet.

If our files are too small, the execution engine will spend additional time 
with the overhead of listing directories, opening S3 files, getting object 
metadata, setting up transfers, reading headers etc. This will significantly 
impact the time and cost of Athena queries. 

Sometimes small files carry more metadata than actual data, resulting in 
increased total size and overhead of processing.

The benefits of larger files include faster listings, fewer Amazons S3 
requests, less metadata to manage, and parallel processing if the file format 
is splittable. However, too large files are not great as well, optimal size is 
somewhere between 200 MB and 1 GB.

AWS gives an example to illustrate the impact of small files:

| Query                         | Number of Files | Runtime     |
|-------------------------------|-----------------|-------------|
| SELECT count(*) FROM lineitem | 100,000 files   | 13 seconds  |
| SELECT count(*) FROM lineitem | 1 file          | 1.3 seconds |
| Speedup                       |                 | ~90%        |

> For more information, please see [Top 10 Performance Tuning Tips for Amazon Athena](https://aws.amazon.com/blogs/big-data/top-10-performance-tuning-tips-for-amazon-athena/){:target="_blank"}

If you are using AWS Glue to process data and export it to a Glue table i.e. S3 
datalake. You are probably familiar with the issue of large number of small files. 
In this post, I'll try to cover ways of controlling the number and size of export 
files in Glue, but also methods of merging small files in a post-processing stage.

I hope you'll find this post useful and as always, please feel free to reach out 
if you have any additional questions and suggestions.

 
## Partitions
 
As we already know, the main idea of parallel processing is to split the input 
data into multiple parts distributing them across different nodes and processing 
them in parallel. This is essential for all distributed systems for large scale 
data processing. In Apache Spark, partitions play a crucial role in determining 
how data is distributed and processed across the cluster. 

A partition is a basic unit of data distribution and it represents a portion of 
a larger dataset that is processed by a single task. The partition count is 
influenced by diverse factors, and selecting the most suitable partition 
quantity can pose a challenge. Achieving the ideal partitioning for a particular 
use case typically demands investigation and comprehension of the input data 
and the resources at hand. Some of the factors to consider when determining the 
right number of partitions include:
- Input data source - for example HDFS block size
- Size and number of input files
- Resources and cluster configuration - number of executor nodes, CPU cores per node, 
RAM memory etc.

The idea of increasing the number of partitions is to have better parallelism, 
enabling efficient utilization of available resources and faster execution. 
However, having too much partitions can lead to worse performance due to increased 
task scheduling and communication overhead, as driver needs to manage and coordinate 
tasks across these partitions and nodes.

Fine-tuning the cluster performance is a huge topic and getting the right configuration 
depends on a particular use case. In this post, we are only interested in how the 
configuration parameters influence the number of export files. 

As the data gets partitioned and processed on different nodes, each node will 
output a part of data. These parts end-up as single files and as a result we can 
have large amount of small files each representing a single part of output data. 
By default, when writing data to output location, each partition of RDD or DataFrame, 
is written as a separate file, resulting in as many output files as there are partitions.

If we don't explicitly specify the number of partitions, Spark will determine 
the number of partitions on read using the `spark.default.parallelism` configuration 
parameter. This parameter is the default parallelism level, representing the number of 
partitions that Spark will use for distributed processing. The number of available 
CPU cores and worker nodes in the cluster significantly affects the optimal value 
for this parameter. 
 
Let's see an example. Running a Glue job with:
- Requested number of workers = 100 and 
- Worker Type = G 1X (4vCPU and 16GB RAM) 

gives the following configuration:
```python
{'aws_glue_job_id': '<id>',
 'context':
    {'configuration':
        [
            ...
            ['spark.driver.cores', '4'],
            ['spark.default.parallelism', '396'],
            ['spark.executor.instances', '99'],
            ['spark.dynamicAllocation.maxExecutors', '99'],
            ['spark.sql.shuffle.partitions', '396'],
            ['spark.glue.GLUE_VERSION', '3.0'],
            ['spark.executor.cores', '4'],
            ...
        ]
    },
 ...
}
```

> To get all parameters use `spark_configurations = spark.sparkContext.getConf().getAll()`

> If you are wondering why `99`. One node is always reserved for a driver which 
> is not used for processing.

This is the most optimal configuration since each worker has 4 CPUs, and each 
partition gets one CPU on one worker i.e. can be independently processed in 
parallel. However, some partition can be larger than others, which affects the 
efficiency of data processing, and repartitioning them guarantees that we are 
having the data uniformly distributed.

> "Stragglers" - task taking longer than others, for example, due to unbalanced 
> amount of data between tasks

### Small files on read

Having hundreds of small input files that are only a few kilobytes can significantly 
impact the performance of a Glue job. As we've seen, the number and size of 
input files affects the number of partitions on read. 

We can improve the data processing speed by defining the groupings of input files 
to enable tasks to read a group of input files into a single in-memory partition. 
Groupings can be configured using the following parameters:
- `groupFiles` - Set this parameter to `inPartition` to enable groupings of files.
This is automatically set by AWS Glue if there are more than 50,000 input files.
- `groupSize` - The target size of groups in bytes. This parameter is optional, if 
not provided, the AWS Glue calculates a size to use all the CPU cores in the cluster 
while still reducing the overall number of ETL tasks and in-memory partitions.

> Please see [Reading input files in larger groups](https://docs.aws.amazon.com/glue/latest/dg/grouping-input-files.html){:target="_blank"}, 
> for more information

Since this configuration affects partitions on read, it will also influence the number 
of exported files. As always, experimenting with different configuration parameters 
will give us a better sense of what works best in our particular use case.

### Repartitioning

Repartitioning means changing the data distribution among nodes within a cluster. 
This procedure can serve as a double-edged sword. When executed effectively, 
it can increase the performance and efficiency of Spark jobs. Conversely, if 
not handled appropriately, it introduces extra load on the entire cluster and 
significantly affects the job's duration.

Since repartitioning redistributes the data, we usually want to perform it when 
we have some imbalance in data distribution, for example:
- If our data is skewed, meaning that some keys have significantly more data 
than the others i.e. imbalanced data partitions
- Before performing joins, aggregations, and groupings. Especially if join keys 
have imbalanced data
- Merging DataFrames with significantly different sizes and skewness in their 
data distribution etc.

There are multiple ways to repartition the data:
- `repartition`
- `coalesce`
- `repartitionByRange`
- `partitionBy`

Understanding the differences between them is essential for picking the right 
partitioning strategy.

#### repartition

`repartition` is very expensive operation since it invokes a full data shuffle 
across all nodes in a cluster. It'll evenly distribute the data and can be used 
to increase or decrease the number of partitions.

We can define the target number of partition and/or single or multiple columns 
to use in repartitioning:
```python
DataFrame.repartition(numPartitions, *cols)
```

Using different arguments will use different partitioning strategies under the 
hood. Let's see some in practice.

Specifying just a number of partitions uses `RoundRobinPartitioning`. We can 
confirm this by examining the execution of the *Physical Plan*:
```python
df = spark.createDataFrame(data=data, schema=schema)
df = df.repartition(2)
df.explain()
```

```text
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- Exchange RoundRobinPartitioning(2), REPARTITION_BY_NUM, [id=#6]
   +- Scan ExistingRDD[employee_name#0,department#1,state#2,salary#3L,age#4L,bonus#5L]
```

where `data` is some test employee data. What's important is 
`Exchange RoundRobinPartitioning(2), REPARTITION_BY_NUM`.

On the other hand, if we specify a single column. Let's say we want to 
repartition on `department`:
```python
df = spark.createDataFrame(data=data, schema=schema)
df = df.repartition("department")
df.explain()
```

```text
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- Exchange hashpartitioning(department#1, 200), REPARTITION_BY_COL, [id=#6]
   +- Scan ExistingRDD[employee_name#0,department#1,state#2,salary#3L,age#4L,bonus#5L]
```

It'll use `HashPartitioning`. This method divides the data into partitions 
based on the hash values of specific columns or expressions. As we haven't 
specified the number of partitions, Spark will take the default number of 
shuffle partitions (`spark.sql.shuffle.partitions = 200`) and assign each 
record to a partition based on the hash value. Doing so will ensure that the 
data is evenly distributed across partitions which allows balanced workloads 
during the processing.

The final options is to use `HashPartitioning` with specific number of partitions:
```python
df = spark.createDataFrame(data=data, schema=schema)
df = df.repartition(2, "department")
df.explain()
```
which gives the following plan

```text
== Physical Plan ==
AdaptiveSparkPlan isFinalPlan=false
+- Exchange hashpartitioning(department#1, 2), REPARTITION_BY_NUM, [id=#6]
   +- Scan ExistingRDD[employee_name#0,department#1,state#2,salary#3L,age#4L,bonus#5L]
```

where we can see that `hashpartitioning` now has `2` as an argument.

#### coalesce

`coalesce` is used to reduce the number of partitions, it cannot be used to 
increase it, compared to `repartition`. However, `coalesce` merges existing 
partitions into a smaller number of partitions without perform full data 
shuffle, which makes it more efficient than `repartition`.

In order to use `coalesce` we have to specify the target number of partitions:
```python
df.coalesce(numPartitions)
```

`coalesce` uses existing partitions to minimize the amount of data that needs 
to be transferred across the nodes. It'll move data from some of the nodes 
and merge it onto others. This process can result in partitions with different 
amounts of data. Partition imbalance reduces the efficiency of processing and 
can make some tasks run longer than others. Having this in mind, `coalesce` should 
be used carefully.

#### repartitionByRange

As we've seen, `repartition` will use `HashPartitioner` to hash column values 
and determine the partition. If we have a continuous, not discrete, column values 
such as numbers, we can use `repartitionByRange` to partition the data based 
on a range of the column values.

The process of determining actual ranges is done by sampling the column to 
estimate the ranges, which makes it inconsistent since sampling can return 
different values.

The sample size can be controlled by the configuration parameter 
`spark.sql.execution.rangeExchange.sampleSizePerPartition`.

We can specify target number of partitions and columns
```python
DataFrame.repartitionByRange(numPartitions, *cols)
```

If number of partitions is not specified, the default number of partitions is 
used defined using the configuration parameter `spark.sql.shuffle.partitions`.

> More information in the documentation [pyspark.sql.DataFrame.repartitionByRange](https://spark.apache.org/docs/3.1.1/api/python/reference/api/pyspark.sql.DataFrame.repartitionByRange.html){:target="_blank"}


#### partitionBy

`partitionBy` is a method of `DataFrameWriter` class which is used to write 
the `DataFrame` to disk in partitions i.e. partitions the output by the given 
columns on the filesystem, one sub-directory for each unique value in partition 
columns.

> Documentation [pyspark.sql.DataFrameWriter.partitionBy](https://spark.apache.org/docs/latest/api/python/reference/pyspark.sql/api/pyspark.sql.DataFrameWriter.partitionBy.html){:target="_blank"}

This is quite different than `repartition`, which is a `DataFrame` method that 
is used to increase or reduce the partitions in memory and when written to disk, 
it creates all part files in a single directory.

It takes a single or multiple columns:

```python
DataFrameWriter.partitionBy(*cols: Union[str, List[str]]) → pyspark.sql.readwriter.DataFrameWriter
```

Since the topic of this post is about the number of exported files, `partitionBy` 
is very important, especially in combination with `repartition`.

The way it works is maybe unexpected at first. The `partitionBy` at write will 
be applied on each partition since each of the original partitions is written 
independently. There is an awesome explanation and example provided 
by conradlee: [Difference between df.repartition and DataFrameWriter partitionBy?](https://stackoverflow.com/a/42780452){:target="_blank"}.

TL;DR of the answer: Let's say we have 10 partitions that span 7 days and we 
want to `partitionBy("date")`. How many files are we going to get? Well, it 
depends on the actual partitions. If we have 7 days in each partitions, we'll 
get 70 files. If each partition has data for exactly one day, we'll have 10 files.

Understanding this is essential for handling the partitions in right way, but 
also for controlling the number of exported files.

## Merging files

Sometimes having large amount of small files is inevitable and we have to 
define a post-processing step in order to merge small files into optimal size and 
number of files.

Merging small files into larger ones in Amazon S3 is a common need to improve 
performance, reduce costs, and optimize storage. Luckily, AWS already offers 
several approaches. We'll explore some of them.  
 
### Glue

We can create a simple Glue ETL job which will read all the small files into 
one DataFrame, which we repartition and export to a new S3 location as a large 
file.
 
```python
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.dynamicframe import DynamicFrame
 
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
 
df = glueContext.create_dynamic_frame.from_options(
    's3',
    {'paths': ['s3://<input-bucket>/']},
    'parquet',
)
partitioned_df=df.toDF().repartition(1)
partitioned_dynamic_df=DynamicFrame.fromDF(partitioned_df, glueContext, "partitioned_df")
 
glueContext.write_dynamic_frame.from_options(
    frame=partitioned_dynamic_df,
    connection_type='s3',
    connection_options={'path': 's3://<output-bucket>/'},
    format='parquet',
)
```

In this example we are creating only 1 partition. However, if the size of 
DataFrame is significantly large, this process can fail due to out-of-memory 
error. One of the ways to handle this is to determine the optimal number of 
partition based on total size of input files and desired target size of output 
files.

The following equation can give us a rough estimate:

<div class="formula">
    $${\Large\mathrm{targetNumPartitions} = \frac{is\;\mathrm{Gb} * 1000}{ts\;\mathrm{Mb}}}$$
</div>
<br>

where `is` and `ts` are input and target size, respectively.

For example, if we have 1 Gb of input data and we want output files of 10 Mb, 
target number partitions will be 100.

> For more information see [AWS Glue FAQ, or How to Get Things Done](https://github.com/aws-samples/aws-glue-samples/blob/master/FAQ_and_How_to.md){:target="_blank"}
 
### Lambda
 
Depending on the number and size of files, we can use a Lambda function to merge 
multiple small files into one.
 
There are multiple ways to achieve this. The one that I find easiest and most 
efficient is by leveraging AWSWrangler i.e. AWS SDK for Pandas.

> Please see [AWS SDK for Pandas - Quick Start](https://aws-sdk-pandas.readthedocs.io/en/stable/){:target="_blank"} 
> for more information
 
AWS already offers an official Lambda layer for AWSWrangler, implementing it in 
existing Lambda functions is pretty straightforward. The library also has built-in 
methods for reading multiple files into one dataframe, which allows us to export 
it in a single file. The    following code should give you an idea how to do that:
 
```python
import awswrangler as wr
 
 
def lambda_handler(event, context):
 
    s3_objects = wr.s3.list_objects('s3://<bucket>/*.parquet')
    dataframe = wr.s3.read_parquet(s3_objects)
    wr.s3.to_parquet(dataframe, 's3://<output_bucket>/merged.parquet')
 
    return {
        'statusCode': 200,
        'body': "Success"
    }
```
 
Note that `list_objects` supports Unix shell-style wildcards in the path 
argument. It gives us a simple way to gather all Glue export parts which 
are divided into multiple parquet files, usually named as `part-0000X-<hash>.snappy.parquet`.
 
Typically, Lambda proves a speedy and straightforward fix, yet it 
remains crucial to confirm that our use case aligns with Lambda's time and 
space constraints.
 

### EMR - S3DistCp

Apache DistCp is an open-source tool you can use to copy large amounts of data. 
S3DistCp is similar to DistCp, but optimized to work with AWS, particularly Amazon S3.

> For more information see documentation [S3DistCp](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/UsingEMR_s3distcp.html){:target="_blank"}

We can use S3DictCp to concatenate files that match the expression using the 
option `--groupBy=PATTERN`. For example, we could combine multiple log files into 
a single one per day/hour.

Target size is defined by specifying `‑‑targetSize=SIZE ` in mebibytes (MiB). 
This sizes defines the size of a whole group based on `--groupBy`. If the 
concatenated group is larger than target size, it'll be broken into multiple 
files and named sequentially with a numeric value.

One important thing is that S3DistCp doesn't support Parquet files. This is a 
huge limitation since Parquet is the preferred file format in datalakes. AWS 
recommends using PySpark instead.
 
## Resources
- [How is a Spark Dataframe partitioned by default?](https://stackoverflow.com/questions/66386963/how-is-a-spark-dataframe-partitioned-by-default){:target="_blank"}
- [How can I configure an AWS Glue ETL job to output larger files?](https://repost.aws/knowledge-center/glue-job-output-large-files){:target="_blank"}
- [HashPartitioning](https://jaceklaskowski.gitbooks.io/mastering-spark-sql/content/spark-sql-HashPartitioning.html){:target="_blank"}
- [Repartition vs Coalesce in Apache Spark ](https://blog.rockthejvm.com/repartition-coalesce/){:target="_blank"}