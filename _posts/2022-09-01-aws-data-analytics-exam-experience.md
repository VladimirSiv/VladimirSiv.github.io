---
title: "AWS Data Analytics Specialty Exam Experience and Study Notes"
page_title: "AWS Data Analytics Exam Experience"
excerpt: "Sharing my AWS Data Analytics Specialty exam experience, resources, tricks and tips, study notes etc."
date: September 1, 2022
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: September 1, 2022
og_image: /assets/images/posts/aws-data-analytics/header.jpg
---

{% include image.html
    src="/assets/images/posts/aws-data-analytics/header.jpg"
    alt="aws-data-analytics-exam"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

Last week I passed the AWS Data Analytics Specialty exam and since many of my 
colleagues and LinkedIn connections asked me to share my experience, I decided 
to write a small blog post.

I hope that this will give you enough information to flatten the 
learning curve and decrease the time needed for exam preparation.

If you have any additional questions and suggestions, please don't hesitate to 
reach out.

I wish you all the best on the exam and I'm sure you'll do great! 🥳 🎉

## Questions

The following are some questions that I had on the exam and insights I gathered:

- I've focused a lot on EMR and everything about the integration of Apache 
projects with AWS services. However, for some reason, I had like ~5 EMR 
questions related to HDFS/EMRFS, Hive, Pig scripts, and Apache Hudi. Honestly, 
I expected more focus on EMR
- On the other hand, I had a lot of questions related to QuickSight, which I 
didn't expect. From how to refresh SPICE using API, managing user space and 
cross-account setups to embedded dashboards, data sources and even graphs. I had 
two questions where they asked me about the best visualization/graph type for 
a particular case
- As expected, Redshift was the center of attention:
  - Encryption types. HSM trick question
  - All kinds of optimizations: Short Query Acceleration, WLM etc
  - [Distribution styles](https://docs.aws.amazon.com/redshift/latest/dg/c_choosing_dist_sort.html){:target="_blank"}
  - [VACUUM](https://docs.aws.amazon.com/redshift/latest/dg/r_VACUUM_command.html){:target="_blank"} 
  (full, sort only, delete only...)  and 
  [ANALYZE](https://docs.aws.amazon.com/redshift/latest/dg/r_ANALYZE.html){:target="_blank"}
  - Table/Column-level permissions: 
  [Achieve finer-grained data security with column-level access control in Amazon Redshift](https://aws.amazon.com/blogs/big-data/achieve-finer-grained-data-security-with-column-level-access-control-in-amazon-redshift/){:target="_blank"}
  - [Snapshots](https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-snapshots.html){:target="_blank"}
- Emphasis was on difference between Real-Time, Near Real-Time, and Batch 
processing
- Trick questions regarding Kinesis. I also had these on practice exams. They 
usually revolve around:
  - Duplicated records on Producer/Consumer side: 
  [Handling Duplicate Records](https://docs.aws.amazon.com/streams/latest/dev/kinesis-record-processor-duplicates.html){:target="_blank"}
  - Size of records for Kinesis Data Stream, Kinesis Firehose and Lambda
  - Kinesis Producer Library buffering, retries, and rate limiting: 
  [KPL Retries and Rate Limiting](https://docs.aws.amazon.com/streams/latest/dev/kinesis-producer-adv-retries-rate-limiting.html){:target="_blank"}
  - Common problems when working with producers/consumers: 
  [Troubleshooting Kinesis Data Streams Consumers](https://docs.aws.amazon.com/streams/latest/dev/troubleshooting-consumers.html){:target="_blank"}, [Troubleshooting Amazon Kinesis Data Streams Producers](https://docs.aws.amazon.com/streams/latest/dev/troubleshooting-producers.html){:target="_blank"}
  - Records out of order
  - Kinesis Producer Library batching and aggregation: [KPL Key Concepts](https://docs.aws.amazon.com/streams/latest/dev/kinesis-kpl-concepts.html){:target="_blank"}
  - `PutRecords` vs `PutRecord` when it comes to failed records: [PutRecords](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html){:target="_blank"}
- Kinesis Analytics SQL vs Flink apps: check pointing, fault tolerance, 
parallel execution
- Athena workgroups, cost usage limits - per-query control limits, 
workgroup-wide control limit
- Glue cross-account crawlers and Data Catalogs: 
[Granting cross-account access](https://docs.aws.amazon.com/glue/latest/dg/cross-account-access.html){:target="_blank"}
- Some random questions: DataSync, DMS, on-prem transfers, Direct Connect etc

## Resources

- [Udemy Course - AWS Certified Data Analytics Specialty](https://www.udemy.com/course/aws-data-analytics/){:target="_blank"} - Great course! It gives a really nice overview of all topics needed for the 
exam. Unfortunately, it doesn't go into details
- [Book - AWS Certified Data Analytics Study Guide with Online Labs: Specialty DAS-C01 Exam](https://www.amazon.com/dp/1119819458/ref=emc_b_5_t){:target="_blank"} - When it comes to studying, books are our 
best friends. Unfortunately, that's not always the case with AWS due to rapid 
changes in technology. I've used this book, it's great, but be aware of 
outdated information
- [Practice Exams - Whizlabs: AWS Certified Data Analytics](https://www.whizlabs.com/aws-certified-data-analytics-specialty/){:target="_blank"} - Couldn't recommend it more. Be sure to go through example 
tests before the actual exam
- [Practice Exams - Udemy: AWS Certified Data Analytics Specialty](https://www.udemy.com/course/practice-exams-aws-certified-data-analytics-specialty/){:target="_blank"} - 
Nice practice exam
- [Udemy Course - AWS Certified Data Analytics Specialty Practice Exams](https://www.udemy.com/course/aws-certified-data-analytics-specialty-practice-exams-amazon/){:target="_blank"} - 
Someone recommended me this one, but I haven't had the time to check it out

Of course, the AWS documentation should be your primary source of information, 
but these courses and practices exams can help you pinpoint topics to focus on, 
since the AWS documentation can be quite overwhelming.

## Tips

- **Read answers first** - Questions can be extremely long and deliberately 
confusing. Sometimes, the best thing to do is to read the answers first. 
By doing so, you'll get the idea of what you should focus on and easily discard 
the noise in the question

- **Just guess it** - Exam lasts for 3 hours and there are 65 questions. If you 
do the quick maths, that's ~2.7min per question. Since questions are quite long, 
it'll take time if you want to understand every detail and re-read the question. 
If the question is unclear, goes into details which you cannot remember, or 
you just get confused - don't get frustrated, just guess it, mark the question 
for review and move on

- **Take breaks** - Reading *À-la-recherche-du-temps-perdu*-type of a question 
requires a lot of attention and focus. At some point your mind will start 
wandering. When that happens, just take a break. Look up at the ceiling or close 
your eyes, think about something else for 5 minutes and then continue

## Study Notes

The following are some of the study notes that I gathered. Everything can be 
found in the official AWS documentation and for some bullets I included a * 
which links to the appropriate AWS documentation. These notes are just 
something that I found interesting and worth remembering, they in no way 
represent everything that needs to be covered for the exam.

Please note that I won't keep this constantly up-to-date and if you find some 
mistakes or outdated information, please inform me and I'll do my best to 
correct it ASAP.

### Kafka MKS

- Best way to size Kafka MSK cluster?
  - Use your on-prem cluster as a guideline
  - MSK calculator for pricing and sizing
- Stores events as a continuous series of records and preserves the order in 
which the records were produced. Data consumers process data from Apache Kafka 
topics on a first-in-first-out basis, preserving the order data was produced 
[*](https://aws.amazon.com/msk/faqs/){:target="_blank"}

### Kinesis Data Stream

- A partition key is used to group data by shard within a stream. It segregates 
the data records belonging to a stream into multiple shards. It uses the 
partition key that is associated with each data record to determine which shard 
a given record belongs to
- Latency can increase if there is an increase in record count or record size 
for each GET request
- Spark Streaming can read and write to Kinesis Data Streams
- For `PutRecords` API a failed record is skipped and all subsequent records 
are processed. Therefore, the `PutRecords` API call does not guarantee data 
record ordering. `PutRecord` API guarantees record ordering when writing to the 
same shard 
[*](https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html){:target="_blank"}
- The `IncomingBytes` and `IncomingRecords` metrics show you the rate at which 
your shard is ingesting data. These metrics will alert you when you have a hot 
shard 
[*](https://docs.aws.amazon.com/streams/latest/dev/monitoring-with-cloudwatch.html){:target="_blank"}

### Kinesis Client Library 

- Instantiates a record processor for each shard
- Kinesis Data Streams shards support up to 1,000 Kinesis Data Streams records 
per second, or 1 MB throughput. The Kinesis Data Streams records per second 
limit binds customers with records smaller than 1 KB. Record aggregation allows 
customers to combine multiple records into a single Kinesis Data Streams 
record. This allows customers to improve their per shard throughput 
[*](https://docs.aws.amazon.com/streams/latest/dev/kinesis-kpl-concepts.html){:target="_blank"}
- After de-aggregating the KDS record use KPL user record sequence number as 
your unique identifier. The KCL subsequence number is used primarily for checkpointing 
[*](https://docs.aws.amazon.com/streams/latest/dev/kinesis-kpl-consumer-deaggregation.html){:target="_blank"}
- If we have KDS with 4 shards and one KCL app, it will process all 4 shards. 
If we add another KCL app, it will balance out with the first KCL app. So each 
KCL app will process 2 shards 
[*](https://docs.aws.amazon.com/streams/latest/dev/shared-throughput-kcl-consumers.html){:target="_blank"}

### Kinesis Producer Library

- Rate limiting is only possible through KPL and is implemented using tokens 
and buckets within Amazon Kinesis
- PutRecords automatically adds any failed records back into the KPL buffer so 
it can be retried
- Changing `RecordMaxBufferedTime` to a higher value will increase your 
aggregate package size. You must restart the KPL app for changes to take effect
- The KPL is written in C++ and runs as a child process to the main process. 
Precompiled native binaries are bundled with Java release and are managed by 
the Java wrapper. KPL requires you to write your producer code in Java. If you 
want to write it using Python use KPL Aggregation and Deaggregation modules for 
AWS Lambda 
[*](https://docs.aws.amazon.com/streams/latest/dev/kinesis-kpl-supported-plats.html){:target="_blank"} [**](https://docs.aws.amazon.com/streams/latest/dev/kinesis-record-deaggregation.html){:target="_blank"}

### Kinesis Firehose

- Limits:
  - Max record size sent to Firehose: 1MB
  - Buffer size: 1MB to 128MB
  - Flush interval: 60 to 900 seconds
- AVRO is not supported
- When a Kinesis data stream is configured as the source of a Firehose delivery 
stream, the Firehose PutRecord and PutRecordBatch operations will be disabled 
[*](https://www.amazonaws.cn/en/kinesis/data-firehose/faqs/){:target="_blank"}
- You can change the delivery stream destination without interrupting the 
flow of data through the delivery stream by using the `UpdateDestination` API 
call 
[*](https://docs.aws.amazon.com/firehose/latest/APIReference/API_UpdateDestination.html){:target="_blank"}
- Can be configured to write the original source data records to another S3 
bucket
- The `SucceedProcessing` metric data in CloudWatch tells you how many records 
were successfully processed over a period of time when using Lambda for 
transformation 
[*](https://docs.aws.amazon.com/firehose/latest/dev/monitoring-with-cloudwatch-metrics.html){:target="_blank"}
- The `TagDeliveryStream` API operation allows you to apply tags to an existing 
delivery stream 
[*](https://docs.aws.amazon.com/firehose/latest/APIReference/API_TagDeliveryStream.html){:target="_blank"}

### Kinesis Data Analytics

- Flink apps can be written in Java or Scala
- Using Flink you can leverage check pointing for fault tolerance while also 
leveraging parallel execution of tasks and allocating resources to implement 
scaling of your app 
[*](https://docs.aws.amazon.com/kinesisanalytics/latest/java/how-fault.html){:target="_blank"}

### DynamoDB

- You can create on-demand backups and enable point-in-time recovery (PITR) 
for your DynamoDB tables
- Row-level security for IAM users is possible with DynamoDB
- ACID transactions are replicated from the source region to the replica 
regions only after the source region change is committed. This is the 
intended design of DynamoDB global tables 
[*](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/transaction-apis.html){:target="_blank"}

### Glue

- To trigger a job after a crawler, use:
  - Lambda function and CloudWatch Event rule
  - AWS Glue workflow
- Glue jobs can be scheduled at a minimum of 5min
- For schemas to be considered similar the following conditions must be true 
[*](https://aws.amazon.com/premiumsupport/knowledge-center/glue-crawler-detect-schema/){:target="_blank"}:
  - The partition threshold is higher than 70%
  - The maximum number of different schemas does not exceed 5
- We can run Glue DataBrew on a schedule to check data quality, schema 
integrity 
[*](https://aws.amazon.com/about-aws/whats-new/2021/11/aws-glue-databrew-data-quality-rules-validate-requirements/){:target="_blank"}
- Glue crawler - for data stored in Redshift and RDS you need to use JDBC 
connector. DynamoDB has the native DynamoDB interface for crawler
- The Glue DynamicFrame does not require schema. It determines the schema in 
real-time while automatically resolving potential schema issues 
[*](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-crawler-pyspark-extensions-dynamic-frame.html){:target="_blank"}
- Glue crawler - for RDS, glue crawlers need all TCP ports open on the 
security group where the data source resides. To protect the database security 
group from outside access via a TCP port you also configure a self-referencing 
inbound rule for all TCP ports 
[*](https://docs.aws.amazon.com/glue/latest/dg/setup-vpc-for-glue-access.html){:target="_blank"}
- Glue worker node types 
[*](https://docs.aws.amazon.com/glue/latest/dg/add-job.html){:target="_blank"}:
  - Standard
  - G.1X - Good for memory intensive jobs, uses 1DPU per worker (1DPU = 4vCPU, 16GB memory, 64GB disk)
  - G.2X - 2DPU per worker. We recommend this worker type for memory-intensive jobs and jobs that run machine learning transforms
  - G.025X - 0.25 DPU per worker. We recommend this worker type for low volume streaming jobs
- When you enable job metrics in your Glue job def, the job initializes a 
`GlueContext` class which is then used to init `SparkContext` 
[*](https://docs.aws.amazon.com/glue/latest/dg/monitoring-awsglue-with-cloudwatch-metrics.html){:target="_blank"}
- The Glue `Unbox` built-in transform reformats string fields, like a JSON 
field, into distinct fields representing the types of the composites 
[*](https://docs.aws.amazon.com/glue/latest/dg/built-in-transforms.html){:target="_blank"}
- When you have multiple concurrent jobs with job bookmarks and the maximum job 
concurrency is not set to 1, the job bookmark does not work correctly 
[*](https://aws.amazon.com/premiumsupport/knowledge-center/glue-reprocess-data-job-bookmarks-enabled/){:target="_blank"}
- For crawler, you have to point it to a bucket/prefix. If you point it to a 
specific file (for example, .csv), it will create a table with correct column 
names but it won't populate the table with data
- The `FindMatches` transform will find duplicate records even when the records 
do not have a common unique identifier and no fields match exactly 
[*](https://docs.aws.amazon.com/glue/latest/dg/machine-learning.html){:target="_blank"}

### Aurora

- Cannot scale past 64TB

### Athena

- Cost control [*](https://docs.aws.amazon.com/athena/latest/ug/workgroups-setting-control-limits-cloudwatch.html){:target="_blank"}:
  - Athena allows you to set two types of cost controls: *per-query limit* and 
  *per-workgroup* limit
  - For each workgroup, you can set only one per-query limit and multiple 
  per-workgroup limits
  - The *workgroup-wide* data usage control limit specifies the total amount 
  of data scanned for all queries that run in this workgroup during the 
  specified time period. You can create multiple limits per workgroup. 
  The workgroup-wide query limit allows you to set multiple thresholds 
  on hourly or daily aggregates on data scanned by queries running in the 
  workgroup 
- To make sure all of your Athena query data is encrypted, you have to encrypt 
the entire Glue data catalog and encrypt the results of your Athena queries 
which Athena stores in S3 result location

### Redshift

- Short Query Acceleration (SQA) can be used in place of WLM as a simple way 
to ensure short queries are not scheduled behind longer ones
- To use Redshift Spectrum with data in an S3 bucket in different account: add 
a policy to the S3 bucket allowing S3 GET and LIST for an IAM role for Spectrum 
on the Redshift account
- To maintain a real-time replica of Redshift cluster across multi AZ: spin up a 
separate cluster in a different AZ and using Kinesis simultaneously write data 
into each cluster. Use Route53 to direct to the nearest cluster when querying 
the data.
- Is not Multi AZ
- Automatically snapshots data to S3
- Can automatically load in parallel from multiple compressed 
data files. Multiple concurrent `COPY` commands are much slower since it forces 
Redshift to perform a serialized load and requires a `VACUUM`. If you want to load 
data in parallel it's better to split the data into separate files no more than 
1GB and use a single `COPY` command 
[*](https://docs.aws.amazon.com/redshift/latest/dg/c_best-practices-single-copy-command.html){:target="_blank"}
- Has much better performance than Athena for complex analytical queries
- Enhanced VPC Routing forces Redshift to use the VPC for all `COPY` and 
`UNLOAD` commands, which can be seen in VPC Flow logs
- Currently, you can only use Amazon S3-managed keys (SSE-S3) encryption 
(AES-256) for audit logging 
[*](https://docs.aws.amazon.com/redshift/latest/mgmt/db-auditing.html){:target="_blank"}
- You can apply compression encodings to columns in tables manually, based on 
your own evaluation of the data. Or you can use the `COPY` command with 
`COMPUPDATE` set to `ON` to analyze and apply compression automatically based 
on sample data 
[*](https://docs.aws.amazon.com/redshift/latest/dg/c_Loading_tables_auto_compress.html){:target="_blank"}
- You can't modify the destination AWS Region after cross-Region snapshot 
copy is configured. If you want to copy snapshots to a different AWS Region, 
first disable cross-Region snapshot copy. Then re-enable it with a new 
destination AWS Region and retention period 
[*](https://docs.aws.amazon.com/redshift/latest/mgmt/managing-snapshots-console.html){:target="_blank"}
- `COPY` command requires three parameters 
[*](https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html){:target="_blank"}:
  - Table name
  - Data source
  - Authorization to access data using an IAM role
- Node types 
[*](https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html){:target="_blank"}:
  - RA3 - if you expect rapid data growth
  - DC2 - if you have less than 10TB, without rapid growth
  - DS2 - legacy nodes, no longer in use
- If we start with a small table but expect rapid growth it's recommended to use 
AUTO distribution style
- Using a stored procedure in Redshift you can limit data access to users. 
When you create a stored procedure, you can set the `SECURITY` attribute to 
either DEFINER or INVOKER. If you specify `SECURITY INVOKER`, the procedure uses 
the privileges of the user invoking the procedure. If you specify 
`SECURITY DEFINER`, the procedure uses the privileges of the owner of the procedure. 
`INVOKER` is the default 
[*](https://docs.aws.amazon.com/redshift/latest/dg/stored-procedure-security-and-privileges.html){:target="_blank"}
- Automatic `VACUUM` operations can pause if the cluster experiences a period 
of high load
- HSM encryption is the most secure encryption you can use on Redshift cluster. 
You cannot modify existing cluster to use HSM. You have to create a new cluster 
with HSM and migrate the data 
[*](https://docs.aws.amazon.com/redshift/latest/mgmt/changing-cluster-encryption.html){:target="_blank"}

### EMR

- Use S3DistCp to copy data from S3 into HDFS and process it locally, upon 
completion use S3DistCp to push the final results back to S3
- Apache Hue and Apache Ambari are graphical front-ends for interacting with a
cluster
- Chunks of 64MB are ideal for HDFS
- Encryption options: LUKS encryption, SSE-KMS, SSE-S3, EBS encryption
- Pig integration with S3 [*](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-pig.html){:target="_blank"}:
  - Directly write to HCatalog tables in S3
  - Submit Pig scripts stored in S3 using EMR console
  - Loading custom JAR files from S3 with the `REGISTER` command
- HBase is designed to be an OLTP engine, allowing an architecture of high-volume 
transactional operations
- HBase integration with S3 [*](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-hbase-s3.html){:target="_blank"}:
  - Snapshots of HBase data to S3
  - Storage of HBase StoreFiles and metadata on S3
  - HBase read-replicas on S3
- To scale cluster based on YARN memory usage use the metric 
`YARNMemoryAvailablePercentage` 
[*](https://docs.aws.amazon.com/emr/latest/ManagementGuide/UsingEMR_ViewingMetrics.html){:target="_blank"}
- To perform actions on data stored in DynamoDB from EMR use Apache Hive 
[*](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/EMRforDynamoDB.html){:target="_blank"}
- Bootstrap actions to install additional software 
[*](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-bootstrap.html){:target="_blank"}:
  - Upload the required installation scripts to S3 and execute them using 
  custom boostrap actions
  - Provision an EC2 instance with Amazon Linux and install the required libs. 
  Create an AMI of it and use it to launch EMR cluster
- To copy data from DynamoDB table into HDFS as csv files, create an external 
Hive table 
[*](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/EMRforDynamoDB.CopyingData.HDFS.html){:target="_blank"}:
```
CREATE EXTERNAL TABLE hdfs_features_csv(...)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
LOCATION 'hdfs:///user/hadoop/hive-test';
INSERT OVERWRITE TABLE hdfs_features_csv SELECT * FROM ddb_features;
```
- For ML apps use Cluster Compute Instance types 
[*](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-supported-instance-types.html){:target="_blank"}
- We can run multiple steps in parallel to improve cluster utilization and save 
cost. The default value for the concurrency level is 10. You can choose between 
2 and 256 steps that can run in parallel 
[*](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-add-steps-console.html){:target="_blank"}
- To add additional steps to a cluster we can use `aws emr add-steps` cli 
command 
[*](https://docs.aws.amazon.com/cli/latest/reference/emr/add-steps.html){:target="_blank"}
- The valid actions on failure for Hive scripts are 
[*](https://docs.aws.amazon.com/emr/latest/ReleaseGuide/emr-hive-differences.html){:target="_blank"}:
  - Terminate cluster: If the step fails, terminate the cluster. If the 
  cluster has termination protection enabled AND keep alive enabled, it will 
  not terminate
  - Cancel and wait: If the step fails, cancel the remaining steps. If the 
  cluster has keep alive enabled, the cluster will not terminate
  - Continue: If the step fails, continue to the next step
- If you have a cluster with multiple users who need different levels of 
access to data in Amazon S3 through EMRFS, you can set up a security 
configuration with IAM roles for EMRFS. EMRFS can assume a different service 
role for cluster EC2 instances based on the user or group making the request, 
or based on the location of data in Amazon S3 
[*](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-emrfs-iam-roles.html){:target="_blank"}
- You can use AWS Service Catalog to centrally manage commonly deployed EMR 
cluster configurations
- Kerberos without EC2 private key file 
[*](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-kerberos-options.html){:target="_blank"}:
  - Cross-realm trust
  - External KDC - cluster KDC on a different cluster with Active Directory 
  cross-realm trust

### S3

- Glacier Select allows you to perform filtering directly against Glacier 
objects using standard SQL
- With S3 Select you can scan a subset of an object by specifying a range of 
bytes to query using the `ScanRange` parameter 
[*](https://docs.aws.amazon.com/AmazonS3/latest/userguide/selecting-content-from-objects.html){:target="_blank"}
- How to check integrity of an object uploaded to S3: To ensure that data is 
not corrupted traversing the network, use the Content-MD5 header. When you use 
this header, Amazon S3 checks the object against the provided MD5 value and, 
if they do not match, returns an error. Additionally, you can calculate the 
MD5 while putting an object to Amazon S3 and compare the returned ETag to 
the calculated MD5 value 
[*](https://docs.aws.amazon.com/AmazonS3/latest/API/API_PutObject.html){:target="_blank"}

### DMS

- You can use DMS data validation to ensure that your data has migrated 
accurately. DMS compares the source and target records and then reports any 
mismatches 
[*](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Validating.html){:target="_blank"}
- When batch fails, DMS breaks the batch down and switches to one-by-one mode 
to apply transactions. After one-by-one for failed batch succeeds it switches 
back to the batch mode 
[*](https://aws.amazon.com/premiumsupport/knowledge-center/dms-task-redshift-bulk-operation/){:target="_blank"}
- One of the ways your migration can slow down is because your source latency 
or target latency is high. To discover the problem monitor CloudWatch entries 
for `CDCLatencySource` and `CDCLatencyTarget`
- If you start a DMS task with CDC you will not migrate views. The only way to 
migrate tables and views is to start full-load only DMS task
[*](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Task.CDC.html){:target="_blank"}
- When migrating CDC we use CDC recovery checkpoint in the source endpoint to 
start the CDC from specific time/point 
[*](https://docs.aws.amazon.com/dms/latest/userguide/CHAP_Task.CDC.html#CHAP_Task.CDC.StartPoint.Checkpoint){:target="_blank"}

### OpenSearch

- To connect securely to Kibana:
  - Set up a reverse proxy server between your browser and Amazon OpenSearch 
  service
  - Set up an SSH tunnel with port forwarding to allow access on port 5601
- To move a Kibana dashboard from one OpenSearch domain to another, simply 
export the dashboard and then import it into the target domain

### QuickSight

- Can read Excel files directly
- Does not support Parquet format while reading the data from S3
- 4 ways to refresh SPICE data 
[*](https://docs.aws.amazon.com/quicksight/latest/user/refreshing-data.html){:target="_blank"}:
  - UI
  - Refresh dataset by editing the dataset
  - Schedule refresh
  - Use `CreateIngestion` API
- Using the Manage QuickSight option in QS console, you can whitelist the 
domains where you wish to have your dashboards embedded 
[*](https://docs.aws.amazon.com/quicksight/latest/user/approve-domain-for-dashboard-embedding.html){:target="_blank"}
- Has ML-powered anomaly detection insight 
[*](https://docs.aws.amazon.com/quicksight/latest/user/anomaly-detection-function.html){:target="_blank"}
- Handles compressed files in `gzip` format automatically
- Can use Presto

### Data Pipeline

- `PigActivity` provides native support for Pig scripts in AWS Data Pipeline 
without requirement to use `ShellCommandActivity` or `EmrActivity` 
[*](https://docs.aws.amazon.com/datapipeline/latest/DeveloperGuide/dp-object-pigactivity.html){:target="_blank"}
- `HiveActivity` makes it easier to set up an EMR activity and automatically 
creates Hive tables to run HiveQL 
[*](https://docs.aws.amazon.com/datapipeline/latest/DeveloperGuide/dp-object-hiveactivity.html){:target="_blank"}
