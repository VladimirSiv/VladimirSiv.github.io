---
title: "Databricks Data Engineer Professional Exam Study Notes"
page_title: "Databricks DE Professional Study Notes"
excerpt: "In this blog post, I'm sharing my preparation notes for the
  Databricks Data Engineer Professional Exam. I hope these will help you
  gather study resources and gain a better understanding of what to focus on
  during your preparation for the exam."
toc: true
toc_label: "Content"
toc_sticky: true
date: March 7, 2025
last_modified_at: March 7, 2025
og_image: /assets/images/posts/databricks-de-pro-prep-notes/header.jpg
---

{% include image.html
    src="/assets/images/posts/databricks-de-pro-prep-notes/header.jpg"
    alt="databricks-de-pro-prep-notes"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

Last week, I passed the Databricks Data Engineer Professional exam and I wanted
to share my preparation notes and resources I used. I hope that this will give
you a better idea of what resources to use and what to focus on during
your preparation for the exam.

The main resources I used:
- [Official Exam Guide](https://www.databricks.com/sites/default/files/2024-05/databricks-certified-data-engineer-professional-exam-guide.pdf){:target="\_blank"}
- Advanced Data Engineering with Databricks - Available in Databricks Academy
- [Udemy - Databricks Certified Data Engineer Professional - Preparation](https://www.udemy.com/course/databricks-certified-data-engineer-professional/){:target="\_blank"}
- [Udemy - Practice Exams: Databricks Data Engineer Professional](https://www.udemy.com/course/practice-exams-databricks-data-engineer-professional-k){:target="\_blank"}
- [Whizlabs - Preparation Guide : Databricks Certified Data Engineer Professional Certification](https://www.whizlabs.com/blog/databricks-certified-data-engineer-professional-guide/){:target="\_blank"}
- [Databricks Certified Data Engineer Professional - Question hints](https://github.com/Amrit-Hub/Databricks-Certified-Data-Engineer-Professional-Questions){:target="\_blank"}

Additional resources:
- [Diving Into Delta Lake: Unpacking The Transaction Log](https://www.databricks.com/blog/2019/08/21/diving-into-delta-lake-unpacking-the-transaction-log.html){:target="\_blank"}
- [Diving Into Delta Lake: Schema Enforcement & Evolution](https://www.databricks.com/blog/2019/09/24/diving-into-delta-lake-schema-enforcement-evolution.html){:target="\_blank"}
- [Stream-Stream Joins using Structured Streaming (Python)](https://docs.databricks.com/aws/en/notebooks/source/stream-stream-joins-python.html){:target="\_blank"}
- [What is change data capture (CDC)?](https://docs.databricks.com/aws/en/dlt/what-is-change-data-capture){:target="\_blank"}

If you have any additional questions and suggestions, please don't hesitate to
reach out.

I wish you all the best on the exam and I'm sure you'll do great! 🥳 🎉

## Streaming

- When performing stream-stream join, Spark buffers past inputs as a streaming
  state for both input streams, so that it can match every future input with
  past inputs. This state can be limited by using watermarks.
- Streaming deduplication - we can use `dropDuplicates()` to eliminate
  duplicate records within each new micro batch. In addition, we need to
  ensure that records to be inserted are not already in the target table.
  We can achieve this using insert-only merge.
- Non-time-based window operations are not supported on streaming DataFrames.
- You should never have two streaming queries use the same checkpoint location
  and run at the same time.
- Streaming workloads using the continuous trigger have the following benefits:
  - Prevent more than one concurrent run of the job
  - Start a new run when a previous run fails
  - Use exponential backoff for task retries
- **Watermarking** in Structured Streaming is a way to limit state in all
  stateful streaming operations by specifying how much late data to consider.
  Specifically, a watermark is a moving threshold in event-time that trails
  behind the maximum event-time seen by the query in the processed data. The
  trailing gap (aka watermark delay) defines how long should the engine wait
  for late data to arrive and is specified in the query using `withWatermark`. 
- **Stream-static** joins are stateless. In stream-static join, the streaming
  portion of this join drives the join process. So, only new data appearing on
  the streaming side of the join will trigger the processing. Adding new
  records into the static table will not automatically trigger updates to the
  results of the stream-static join.

- **Stream-steam** joins are stateful. Databricks recommends specifying
  watermarks for both sides of all stream-stream joins.

```python
from pyspark.sql.functions import expr

# Define watermarks
impressionsWithWatermark = impressions \
  .selectExpr("adId AS impressionAdId", "impressionTime") \
  .withWatermark("impressionTime", "10 seconds ")
clicksWithWatermark = clicks \
  .selectExpr("adId AS clickAdId", "clickTime") \
  .withWatermark("clickTime", "20 seconds")


# Inner join with time range conditions
display(
  impressionsWithWatermark.join(
    clicksWithWatermark,
    expr(""" 
      clickAdId = impressionAdId AND 
      clickTime >= impressionTime AND 
      clickTime <= impressionTime + interval 1 minutes    
      """
    )
  )
)
```

- Deleting data from a streaming source table breaks the append-only requirement
  of streaming sources! To avoid this, you can use the `ignoreDeletes` option
  when streaming from this table. This option enables stream processing from
  Delta tables with partition deletes. Use `.option("ignoreDeletes", True)`.
- When updating the schema of a streaming job by adding new fields, it's
  important to use a new checkpoint location. This is because the existing
  checkpoint location is tied to the old schema, and adding a new field
  could lead to schema mismatch issues.
- Structured Streaming provides exactly-once processing guarantees, but does
  not automatically deduplicate records from data sources. You can use
  `dropDuplicatesWithinWatermark` to deduplicate records on any specified
  field, allowing you to remove duplicates from a stream even if some
  fields differ (such as event time or arrival time).

## Delta Table

- The Delta Lake VACUUM function skips any directories that begin with `_`. You
  can safely store checkpoints alongside other data and metadata for a Delta
  Table using a directory structure such as `<table_name>/_checkpoints`.
- Cloning can occur incrementally. Executing
  `CREATE OR REPLACE TABLE <table> DEEP CLONE <table>` can sync changes from
  the source to the target destination.
- In the **Transaction log**, Delta Lake captures statistics for each data file
  of the table. Total number of records, min/max/null value counts for
  each column of the first 32 columns of the table.
- VACUUM removes data files no longer referenced by a Delta table if they 
  are older than the retention threshold, which is 7 days by default.
- Merge operation cannot be performed if multiple source rows matched and
  attempted to modify the same target row in the table. The result may be
  ambiguous as it is unclear which source row should be used to update or
  delete the matching target row.
- Delta Lake does not enforce **foreign key** constraints across tables. Therefore,
  the data engineer needs to be aware that Databricks does not automatically
  enforce referential integrity between tables through foreign key
  constraints, and it becomes the responsibility of the data engineer to manage
  these relationships appropriately.
- The following types of schema changes are eligible for schema evolution
  during table appends or overwrites. For these we use
  `.option('mergeSchema', 'true')` on `write` and `writeStream`.
  - Adding new columns - most common scenario
  - Changing of data type from `NullType` -> any other type, or upcasts from
    `ByteType` -> `ShortType` -> `IntegerType`
- The following changes are not eligible for schema evolution require that
  the schema and data are overwritten by adding
  `.option('overwriteSchema', 'true')`, these changes include:
  - Dropping a column
  - Changing an existing column's data type
  - Renaming column names that differ only by case e.g. 'Foo' and 'foo'
- Table history retention is determined by the table setting
  `delta.logRetentionDuration`, which is 30 days by default.
- **Constraints** - Databricks supports standard SQL constraint management
  clauses. Constraints fall into two categories:
    - Informational primary key and foreign key constraints encode
      relationships between fields in tables and <ins>are not enforced</ins>.
    - Enforced constraints ensure that the quality and integrity of data added
      to a table is automatically verified.
      - `NOT NULL` - indicates that values in specific columns cannot be null.
      - `CHECK` - indicates that a specified boolean expression must be true
        for each input row.
- **Slowly Changing Dimensions** - SCD types:
  - Type 0 - Fixed Dimension -  In the case of Type 0 dimensions, there are
    no changes whatsoever. The primary uses for static data are when the data
    does not change over time, for example; states, zip codes, county codes,
    SSN, and date of birth etc.
  - Type 1 - Overwrite - For changes in Type 1 dimensions; overwriting is
    used where the new value simply replaces the old value that was already
    stored.
  - Type 2 - Add New Row - Used to track historical changes in dimension data
    by creating a new record whenever a change occurs, preserving the previous
    records. This method ensures a complete history of data changes over time,
    typically by using versioning, effective dates, or flags to differentiate
    between current and past records.
  - Type 3 - Add New Column - Tracks limited historical changes in dimension
    data by storing the previous value along with the current value in the
    same record, often using additional columns. This method is useful when
    only the most recent change history is needed, rather than maintaining a
    complete change history like in SCD Type 2.
  - Type 4 - History Table - manages historical data by maintaining two
    separate tables: one for current dimension data and another for historical
    changes. This approach allows for efficient querying of both current and
    historical records while keeping the main dimension table optimized for
    performance.
  
## Optimizations

- **Broadcast Join** is an optimization technique used in the Spark SQL engine.
  It is utilized when one of the DataFrames is small enough to be stored in the
  memory of all executor nodes. This technique greatly improves the performance
  of join operations by minimazing data shuffling across the network. Broadcast
  join is especially advantageous when working with large datasets and can
  significantly decrease the query execution time. Use
  `pyspark.sql.functions.broadcast` to mark a DataFrame as small enough for
  use in broadcast joins.
- Databricks recommends setting the table property
  `delta.tuneFileSizeForRewrites` to `true` for all tables that are
  targeted by many `MERGE` and DML operations regardless of DBR, UC or other
  optimizations. When set to true the target file size for the table is set to
  a much lower threshold which accelerates write-intensive operations.
- For complex ETL jobs, such as those that require UNIONs and JOINs across
  multiple tables, Databricks recommends using fewer workers to reduce the
  amount of data shuffled. To compensate for having fewer workers, increase
  the size of your instance.
- **Push-down predicate** is a query optimization technique which enables
  developers to filter data at the data source, reducing the amount of
  data transmitted and processed. Predicate is in the WHERE clause of a
  query. The term predicate push-down comes from the fact that you are
  hinting the scan operator with the predicate that is going to be used to
  filter the rows of interest.
- **Optimized Writes** - improve file size as data is written and benefit
  subsequent reads on the table. Optimized writes are most effective for
  partitioned tables, as they reduce the number of small files written to
  each partition. Writing fewer large files is more efficient than writing
  many small files, but you might still see an increase in write latency
  because data is shuffled before being written.
- **Auto compaction** - combines small files within Delta table partitions
  to automatically reduce small file problems. It occurs after a write to a
  table has succeeded and runs synchronously on the cluster that has
  performed the write. You can control the output file size by setting
  `spark.databricks.delta.autoCompact.maxFileSize`. Databricks recommend using
  autotuning based on workload or table size. Auto compaction is only triggered
  for partitions or tables that have at least a certain number of small files.
  You can change the minimum number of files by setting
  `spark.databricks.delta.autoCompact.minNumFiles`.

## Change Data Feed

- Databricks recommends using change data feed in combination with Structured
  Streaming to incrementally process changes from Delta tables.
- Enabling CDF causes a small increase in storage costs for a table.
- Databricks records change data for UPDATE, DELETE, and MERGE operations
  in the `_change_data` folder under the table directory.
- The files in the `_change_data` folder follow the retention policy of the
  table. CDF data is deleted when the VACUUM command runs.
- Set the option `readChangeFeed` to true when configuring a stream against a
  table to read the change data feed, as shown in the following syntax example:

```python
(spark.readStream
  .option("readChangeFeed", "true")
  .table("myDeltaTable")
)
```

- Default behavior, the first batch is processed when the stream first records
  all existing records in the table as `INSERT` operations in the change data
  feed. If your target table already contains all the records with appropriate
  changes up to a certain point, specify a starting version to avoid processing
  the source table state as `INSERT` events.

```python
(spark.readStream
  .option("readChangeFeed", "true")
  .option("startingVersion", 76)
  .table("source_table")
)
```

- You can use batch query syntax to read all changes starting from a particular
  version or to read changes within a specified range of versions. The
  following syntax examples demonstrate using starting and ending version
  options with batch reads:

```sql
-- version as ints or longs e.g. changes from version 0 to 10
SELECT * FROM table_changes('tableName', 0, 10)

-- timestamp as string formatted timestamps
SELECT * FROM table_changes('tableName', '2021-04-21 05:45:46', '2021-05-21 12:00:00')

-- providing only the startingVersion/timestamp
SELECT * FROM table_changes('tableName', 0)

-- database/schema names inside the string for table name, with backticks for escaping dots and special characters
SELECT * FROM table_changes('dbName.`dotted.tableName`', '2021-04-21 06:45:46' , '2021-05-21 12:00:00')
```

- In addition to the data columns from the schema of the Delta table, change
  data feed contains metadata columns that identify the type of change event:
  - `_change_type` - String - insert, update_preimage , update_postimage, 
    delete (1)
  - `_commit_version` - Long - The Delta log or table version containing the
    change.
  - `_commit_timestamp` - Timestamp - The timestamp associated when the commit
    was created.
- Change data feed is not intended to serve as a permanent record of all
  changes to a table. Change data feed only records changes that occur after
  it’s enabled. If your use case requires maintaining a permanent history of
  all changes to a table, you should use incremental logic to write records
  from the change data feed to a new table. The following code example
  demonstrates using `trigger.AvailableNow`, which leverages the incremental
  processing of Structured Streaming but processes available data as a batch
  workload. You can schedule this workload asynchronously with your main
  processing pipelines to create a backup of change data feed for auditing
  purposes or full replayability.

```python
(spark.readStream
  .option("readChangeFeed", "true")
  .table("source_table")
  .writeStream
  .option("checkpointLocation", <checkpoint-path>)
  .trigger(availableNow=True)
  .toTable("target_table")
)
```

## Permissions

- Databricks Jobs must have exactly one owner. `OWNER` privileges cannot be
  assigned to a group.
- Databricks Notebook permissions: `NO PERMISSIONS`, `CAN READ`, `CAN RUN`,
  `CAN EDIT`, and `CAN MANAGE`.
- You cannot manage permissions on secrets, only on secret scopes.
  - Note for Azure - Secret ACLs are at the scope level. If you use Azure
    Key Valut-backed scopes, users that are granted access to the scope have
    access to all secrets in the Azure Key Vault. To restrict access, use
    separate Azure Key Vault instances.
- Compute permissions: `NO PERMISSIONS`, `CAN ATTACH TO`, `CAN RESTART`,
  `CAN MANAGE`
- You cannot access a table with row filters or column masks from a dedicated
  resources on DBR 15.3 or below. You can use dedicated access mode on DBR 15.4
  or above if your workspace is enabled for serverless compute. You might
  therefore be charged for serverless compute resources when you use dedicated
  compute to read dynamic views.
- Databricks recommends using Unity Catalog for all new DLT pipelines.
  By default, materialized views and streaming tables created by pipelines
  configured with Unity Catalog can only be queried by the pipeline owner.
- DLT pipelines process updates using the identity of the pipeline owner.
  Assign a new pipeline owner to change the identity used to run the
  pipeline. Pipeline updates can be run by any user or service principal with
  `CAN RUN`, `CAN MANAGE`, or `IS OWNER` permissions.
- By default, only the DLT pipeline owner and workspace admins can view the
  driver logs from the cluster that runs a Unity Catalog-enabled pipeline.
  You can enable access to the driver logs for any user with `CAN MANAGE`,
  `CAN VIEW`, or `CAN RUN` permissions by adding the following Spark configuration
  parameter to the configuration object in the pipeline settings:

```json
{
  "configuration": {
    "spark.databricks.acl.needAdminPermissionToViewLogs": "false"
  }
}
```

## Delta Live Tables

- You cannot use Delta Sharing to share materialized views and streaming
  tables created by a DLT pipeline.
- Materialized views and streaming tables published from a DLT pipeline,
  including those created by Databricks SQL can be accessed only by Databricks
  clients and applications. However, to make them accessible externally, you can
  use the DLT sink API to write to tables in an external Delta instance.
- Auto Loader supports two modes for detecting new files: **directory listing**
  and **file notification**. 
  - In directory listing mode, Auto Loader identifies new files by listing the
    input directory. Directory listing mode allows you to quickly start Auto
    Loader streams without any permission configurations other than access to
    your data on cloud storage.
  - File notification mode leverages file notification and queue services in
    your cloud infrastructure account. Auto Loader can automatically set up a
    notification service and queue service that subscribe to file events from
    the input directory.
- **Expectations** are optional clauses in pipeline materialized view,
  streaming table, or view creation statements that apply data quality checks
  on each record passing through a query. Expectations use standard SQL Boolean
  statements to specify constraints. You can combine multiple expectations for
  a single dataset and set expectations across all dataset declarations in a
  pipeline.

```python
@dlt.table
@dlt.expect("valid_customer_age", "age BETWEEN 0 AND 120")
def customers():
  return spark.readStream.table("datasets.samples.raw_customers")
```
- The constraint clause is a SQL conditional statement that must evaluate to
  true or false for each record. The constraint contains the actual logic for
  what is being validated. When a record fails this condition, the expectation
  is triggered.

```python
# Simple constraint
@dlt.expect("non_negative_price", "price >= 0")

# SQL functions
@dlt.expect("valid_date", "year(transaction_date) >= 2020")

# CASE statements
@dlt.expect("valid_order_status", """
   CASE
     WHEN type = 'ORDER' THEN status IN ('PENDING', 'COMPLETED', 'CANCELLED')
     WHEN type = 'REFUND' THEN status IN ('PENDING', 'APPROVED', 'REJECTED')
     ELSE false
   END
""")

# Multiple constraints
@dlt.expect("non_negative_price", "price >= 0")
@dlt.expect("valid_purchase_date", "date <= current_date()")

# Complex business logic
@dlt.expect(
  "valid_subscription_dates",
  """start_date <= end_date
    AND end_date <= current_date()
    AND start_date >= '2020-01-01'"""
)

# Complex boolean logic
@dlt.expect("valid_order_state", """
   (status = 'ACTIVE' AND balance > 0)
   OR (status = 'PENDING' AND created_date > current_date() - INTERVAL 7 DAYS)
""")
```
- Actions on invalid record:
  - `WARN` - default - Invalid records are written to the target. The count of
    valid and invalid records is logged alongside other dataset metrics.
  - `DROP` - Invalid records are dropped before data is written to the target.
    The count of dropped records is logged alongside other dataset metrics.
  - `FAIL` - Invalid records prevent the update from succeeding. Manual
    intervention is required before reprocessing. This expectation causes a
    failure of a single flow and does not cause other flows in your pipeline
    to fail.
- DLT simplifies change data capture (CDC) with the APPLY CHANGES and
  APPLY CHANGES FROM SNAPSHOT APIs. The interface you use depends on the
  source of change data:

## Compute

- If you stop a job run in the middle of execution, any actions that have
  already been committed to Delta tables will persist. However, any uncommitted
  changes made by the job will be rolled back.
- Difference between `%sh pip` and `%pip`:
  - `%sh pip` just executes the pip command on the local driver machine. By
    itself, this does not establish a virtual environment, so other users of
    the cluster could observe the installed package.
  - `%pip` uses the same syntax to install package but the command actually
    runs to install the same package across all nodes in the cluster. It sets
    up a virtual environment specific to each notebook execution to isolate
    the package installation from other jobs and users.
- You can export the logs for your job run. Set up your job to automatically
  deliver logs to S3 while configuring job compute, or through the Job API.
- **Cluster Event Log** provides detailed information about various events
  affecting the cluster throughout its lifecycle, including cluster creation,
  restarts, termination, and resizing events. It displays the timestamp, event
  type e.g. CLUSTER_RESIZED, and relevant details for each event, allowing the
  admins to review the timeline for cluster scaling behavior.
- The maximum concurrent runs for all new jobs is 1. Databricks skips the run
  if the job has already reached its maximum number of active runs when
  attempting to start a new run. Set concurrency > 1 to allow multiple
  concurrent runs of the same job.
- To prevent runs of a job from being skipped because of concurrency limits,
  you can enable queueing for the job. When queueing is enabled, the run is
  queued for up to 48h if resources are unavailable for a job run. Queued runs
  are displayed in the runs list of the job. Queueing is a job-level
  property that queues runs only for that job.
- `mlflow.pyfunc.spark_udf` - a Spark UDF that can be used to invoke the Python
  function formatted model. Parameters passed to the UDF are forwarded to the
  model as a DataFrame where the column names are ordinals (0, 1, ...).
- Create a new column based on function return value - for example model 
  UDF pyfunc:
  `df.select("<column>", ..., predict_udf(*column_list).alias("prediction"))`