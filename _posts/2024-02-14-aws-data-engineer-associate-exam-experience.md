---
title: "AWS Data Engineer Associate Exam Experience and Study Notes"
page_title: "AWS Data Engineer Associate Exam Experience"
excerpt: "Sharing my AWS Data Engineer Associate exam experience, resources, tricks and tips, study notes etc."
date: February 14, 2024
toc: true
toc_label: "Content"
toc_sticky: true
last_modified_at: February 14, 2024
og_image: /assets/images/posts/aws-data-engineer-associate-exam/header.jpg
---

{% include image.html
    src="/assets/images/posts/aws-data-engineer-associate-exam/header.jpg"
    alt="aws-data-engineer-associate-exam"
    caption="Image Source: <a href='https://www.pexels.com/' target='_blank'>Pexels</a>"
%}

Last week I passed the AWS Data Engineer Associate Beta exam and since many of my
colleagues and LinkedIn connections asked me to share my experience, I decided
to write a small blog post.

I hope that this will give you enough information to flatten the
learning curve and decrease the time needed for exam preparation.

Please note that I completed this exam during its Beta phase, so my perspective
on the questions may vary slightly from the official test. Nevertheless, the
fundamental concept of the exam remains consistent.

If you have any additional questions and suggestions, please don't hesitate to
reach out.

I wish you all the best on the exam and I'm sure you'll do great! 🥳 🎉

## Questions

Having completed this exam during its Beta phase, I found that certain
questions appeared elementary to me, while others were notably advanced - on
expert level, seemingly surpassing the associate level in my opinion. I also
came across a few unclear and confusing questions, which I presume have been
rephrased and corrected for the official exam.

The difficulty level of questions fluctuated considerably during the Beta exam,
but the topics covered should remain consistent. I would categorize the exam
into the following three broad topics:

- **Data Extract**
  - Questions  regarding data ingestion across various scenarios: real-time, 
    batch, and near real-time. This involves platforms such as S3, Kinesis, 
    Glue, Lambda, and others
  - Data migration in general - moving databases from on-premises to cloud, 
    different scenarios of how to get data from source to destination
  - DMS, Change Capture Data, data replication, schema change - in one go, 
    incremental...

- **Data Transform**
  - I would say that proficiency in understanding Glue and Athena is crucial 
    for the exam, as the majority of the content revolves around these two 
    services and their integration with other AWS services
  - EMR was mentioned a couple of times, but nothing very specific, mostly some
    basic stuff
  - What was interesting is that DataBrew was mentioned and I would say, in
    very specific use cases, for example: Which DataBrew transformation would
    you use in order to get...?
  - There were a lot of questions regarding orchestration, mainly using Step
    Function and Glue Workflow
  - I had questions related to deduplication, anonymization, anomaly detection
    in general, but also related to some services, example: Glue

- **Data Loading**
  - Numerous questions centered on selecting the optimal solution for 
    different data storage requirements, considering platforms such as S3, 
    Redshift, Lake Formation, DynamoDB, and RDS, depending on the specific use 
    case
  - Exploring cross-stack queries i.e. querying across different services, 
    for example: Athena Federated Query, Redshift Spectrum...
  - Glue Catalog was mentioned multiple times and its use in integration with
    other AWS services
  - Scenario questions where we have to transform some data and load it
    somewhere else, the question is what's the most optimal and cost-effective
    way to achieve it - load it into Redshift, create a Glue job, use Athena
    to transform and load. While all answers are valid, one solution is deemed 
    the most efficient
  - Be sure to cover QuickSight and how the data can be loaded into dashboards,
    there were some questions related to integration of Athena with QuickSight

## Resources

- [Udemy Course - AWS Certified Data Engineer Associate 2024](https://www.udemy.com/course/aws-data-engineer/){:target="\_blank"} - It gives a really nice overview of all topics needed for
  the exam. Unfortunately, it wasn't available and adjusted to the exam during
  the Beta phase.
- I've used the following AWS whitepapers in order to prepare for the exam:
  - [Build Modern Data Streaming Architectures on AWS](https://docs.aws.amazon.com/whitepapers/latest/build-modern-data-streaming-analytics-architectures/build-modern-data-streaming-analytics-architectures.html?did=wp_card&trk=wp_card){:target="\_blank"}
  - [AWS Glue Best Practices: Building a Performant and Cost Optimized Data Pipeline ](https://docs.aws.amazon.com/whitepapers/latest/aws-glue-best-practices-build-performant-data-pipeline/aws-glue-best-practices-build-performant-data-pipeline.html?did=wp_card&trk=wp_card){:target="\_blank"}
  - [AWS Glue Best Practices: Building an Operationally Efficient Data Pipeline](https://docs.aws.amazon.com/whitepapers/latest/aws-glue-best-practices-build-efficient-data-pipeline/aws-glue-best-practices-build-efficient-data-pipeline.html?did=wp_card&trk=wp_card){:target="\_blank"}
  - [AWS Glue Best Practices: Building a Secure and Reliable Data Pipeline](https://docs.aws.amazon.com/whitepapers/latest/aws-glue-best-practices-build-secure-data-pipeline/aws-glue-best-practices-build-secure-data-pipeline.html){:target="\_blank"}
- Since I passed AWS Data Analytics Specialty, I've also used [Udemy Course - AWS Certified Data Analytics Specialty](https://www.udemy.com/course/aws-data-analytics/){:target="\_blank"} to quickly
  review topics requiring a slight refresher

Of course, the AWS documentation should be your primary source of information,
but these courses can help you pinpoint topics to focus on,
since the AWS documentation can be quite overwhelming.

## Study Notes

The following are some of the study notes that I gathered. Everything can be
found in the official AWS documentation and for some bullets I included a \*
which links to the appropriate AWS documentation. These notes are just
something that I found interesting and worth remembering, they in no way
represent everything that needs to be covered for the exam.

Please note that I won't keep this constantly up-to-date and if you find some
mistakes or outdated information, please inform me and I'll do my best to
correct it ASAP.

### General Concepts

- Data Lineage
  - A visual representation that traces the flow and transformation of data
  through its lifecycle, from its source to its final destination
  - We can use AWS Neptune, a graph database, to handle the lineage from 
  different services, and create visualizations

- Data Skew Mechanisms
  - Refers to unequal distribution or imbalance of data across various nodes 
  or partitions in distributed computing systems.
  - Causes
    - Non-uniform distribution of data
    - Inadequate partitioning strategy
    - Temporal skew
  - Techniques to address it
    - Adaptive Partitioning - Dynamically adjust partitioning based on data 
    characteristics to ensure a more balanced distribution
    - Salting - Introduce a random factor or salt to the data to distribute it 
    more uniformly
    - Re-partitioning - Regularly redistribute the data based on its current 
    distribution characteristics
    - Sampling - Use a sample of the data to determine the distribution and 
    adjust the processing strategy

- Data validation and profiling
  - Completeness
    - Ensures all required data is present and no essential parts are missing
    - Checks: missing values, null counts, percentage of populated fields
  - Consistency
    - Ensures data values are consistent across datasets and do not contradict 
    each other
    - Checks: Cross-field validation, comparing data from different sources or 
    periods
  - Accuracy
    - Ensures data is correct, reliable, and represents what it is supposed to
    - Checks: Comparing with trusted sources
  - Integrity
    - Ensures data maintains its correctness and consistency
    - Checks: Referential integrity e.g. foreign key checks in databases, 
    relationship validations etc

### Glue

- Glue DataBrew
  - Visual data preparation tool with over 250 ready-made transformations
  - Create recipes of transformations that can be saved as jobs within a 
  larger project
  - Define data quality rules
  - Create datasets with custom SQL from Redshift and Snowflake [*](https://aws.amazon.com/blogs/big-data/use-sql-queries-to-define-amazon-redshift-datasets-in-aws-glue-databrew/){:target="_blank"}
  - DataBrew is specifically built for fast transforming of a dataset, not 
  for workflows. If we want to define complicated workflows, we should use
  Glue Studio since it supports workflow DAGs
- Glue Dynamic Frame
  - FindMatches - identify duplicate or matching records in your dataset, 
  even when the records do not have a common unique identifier and no fields 
  match exactly [*](https://docs.aws.amazon.com/glue/latest/dg/machine-learning.html){:target="_blank"}
  - ResolveChoice - deals with ambiguities in a DynamicFrame and returns a new 
  one, for example: two fields with the same name but different types [*](https://docs.aws.amazon.com/glue/latest/dg/aws-glue-api-crawler-pyspark-transforms-ResolveChoice.html#aws-glue-api-crawler-pyspark-transforms-ResolveChoice-__call__){:target="_blank"}
    - `make_cols` - Resolves a potential ambiguity by flattening the data. 
    For example, if `columnA` could be an int or a string, the resolution is to 
    produce two columns named `columnA_int` and `columnA_string` in the resulting 
    DynamicFrame
    - `cast` - Allows you to specify a type to cast to\
    - `make_struct` - Resolves a potential ambiguity by using a struct to 
    represent the data. For example, if data in a column could be an `int` or a 
    `string`, using the `make_struct` action produces a column of structures in 
    the resulting DynamicFrame with each containing both an `int` and a `string`
    - `project` - Resolves a potential ambiguity by retaining only values of 
    a specified type in the resulting DynamicFrame. For example, if data in a 
    `ChoiceType` column could be an `int` or a `string`, specifying a 
    `project:string` action drops values from the resulting DynamicFrame that 
    are not type string
- Glue Development Endpoints
  - Develop ETL scripts using a notebook
  - Endpoint is in a VPC controlled by security groups, connect via:
    - Apache Zeppelin
    - SageMaker notebook
    - PyCharm Professional
    - Terminal etc
- Glue DataBrew Personal Identifiable Information (PII) recipe steps [*](https://docs.aws.amazon.com/databrew/latest/dg/recipe-actions.pii.html){:target="_blank"}
  - `REPLACE_WITH_RANDOM` - substitution
  - `SHUFFLE_ROWS` - shuffling
  - `DETERMINISTIC_ENCRYPT` - deterministic 1:1 encryption
  - `ENCRYPT` - probabilistic encryption - more than 1 result from encrypted 
  field
  - `DECRYPT` - decryption
  - `DELETE` - nulling or deleting
  - `MASK_CUSTOM`, `MASK_DATE`, `MASK_DELIMITER`, `MASK_RANGE` - masking out
  - `CRYPTOGRAPHIC_HASH` - hashing - multiple values can hash to the same end 
  result

### Lake Formation

- Supports Governed Tables [*](https://aws.amazon.com/blogs/aws/aws-lake-formation-general-availability-of-cell-level-security-and-governed-tables-with-automatic-compaction/){:target="_blank"}
  - Governed Table is a new type of S3 table that makes it simple and reliable 
  to ingest and manage data at any scale. Governed tables support ACID 
  transactions that let multiple users concurrently and reliably insert and 
  delete data across multiple governed tables. ACID transactions also let you 
  run queries that return consistent and up-to-date data. In case of errors in 
  your extract, transform, and load (ETL) processes, or during an update, 
  changes are not committed and will not be visible
- Granular Access Control with Row and Cell-Level Security – You can control 
access to specific rows and columns in query results and within AWS Glue ETL 
jobs based on the identity of who is performing the action. In this way, you 
don’t have to create (and keep updated) subsets of your data for different 
roles and legislations. This works for both governed and traditional S3 tables
- Data permissions
  - Can tie to IAM users/roles, or external AWS accounts
  - Can use policy tags on database, tables, or columns
  - Can select specific permissions for tables or columns
- Implement column-level, row-level, and cell-level security by creating data 
filters. You select a data filter when you grant the SELECT Lake Formation 
permission on tables. If your table contains nested column structures, you can 
define a data filter by including or excluding the child columns and define 
row-level filter expressions on nested attributes [*](https://docs.aws.amazon.com/lake-formation/latest/dg/data-filters-about.html){:target="_blank"}

### Athena

- Supports Apache Iceberg [*](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg.html){:target="_blank"}
  - Athena supports read, time travel, write, and DDL queries for Apache 
  Iceberg tables that use the Apache Parquet format for data and the AWS Glue 
  catalog for their metastore
  - Removes the need for custom record locking
  - Supports ACID
  - Compatible with EMR, Spark etc anything that supports Iceberg table format
  - Time travel and version travel queries [*](https://docs.aws.amazon.com/athena/latest/ug/querying-iceberg-table-data.html){:target="_blank"}
  - We need to manually perform compaction because ACID stores a bunch of 
  metadata that will degrade Athena queries over time. Compactions optimize 
  the structural layout of the table without altering table content 
  `OPTIMIZE iceberg_table REWRITE DATA USING BIN_PACK WHERE catalog = '<name>'`. 
  In LakeFormation i.e. Governed Tables, this is done automatically for us
- Athena Fine-grained Access to Glue Catalog [*](https://docs.aws.amazon.com/athena/latest/ug/fine-grained-access-to-glue-resources.html){:target="_blank"}
  - IAM based Database and table-level security
    - Broader than data filters in LF
    - Cannot restrict to specific table version
  - Might have policies to restrict access to: ALTER/CREATE TABLE, DROP 
  DATABASE/TABLE, MSCK REPAIR TABLE, SHOW etc. These operations have mappings 
  to IAM actions. For example "DROP TABLE" -> "glue:DeleteTable". We also need 
  permission to drop partitions within a table "glue:DeletePartition" in order 
  to delete a table
- Athena for Apache Spark [*](https://docs.aws.amazon.com/athena/latest/ug/notebooks-spark.html){:target="_blank"}
  - We can run Apache Spark directly on Athena
  - Running Apache Spark applications on Athena means submitting Spark code 
  for processing and receiving the results directly without the need for 
  additional configuration
  - Apache Spark on Amazon Athena is serverless and provides automatic, 
  on-demand scaling that delivers instant-on compute to meet changing data 
  volumes and processing requirements
  - Ways to use it:
    - Console - Submit your Spark applications from the Amazon Athena console
    - Scripting - Quickly and interactively build and debug Apache Spark 
    applications in Python
    - Notebook - Use the Athena notebook editor to create, edit, and run 
    computations using a familiar interface. Athena notebooks are compatible 
    with Jupyter notebooks and contain a list of cells that are executed in 
    order as calculations

### QuickSight

- Sources: Redshift, Aurora, RDS, Athena, OpenSearch, IoT Analytics, EC2 
hosted databases, S3 or on-prem files
- SPICE [*](https://docs.aws.amazon.com/QuickSight/latest/user/spice.html){:target="_blank"}
  - Super-fast Parallel In-memory Calculation Engine
  - Uses columnar storage, machine code generation
  - Each user gets 10GB of SPICE
  - Refresh SPICE data [*](https://docs.aws.amazon.com/QuickSight/latest/user/refreshing-imported-data.html){:target="_blank"}
    - Manual dataset refresh
    - Incremental dataset refresh
    - Refresh during data preparation
    - Refresh dataset on a schedule
    - Incremental dataset refresh on a schedule
- Can accelerate large queries that would timeout in direct query mode - 
hitting Athena directly
- Cross-account, cross-region
  - To cross-account/region you need QuickSight with an Enterprise Edition 
  subscription. One of the differences between this edition and the Standard 
  Edition is the ability to connect QuickSight to a VPC—through an ENI and keep 
  network traffic private within the AWS network. Connect two VPC using VPC 
  peering, AWS Transit Gateway, PrivateLink, VPC sharing, and establish a 
  connection with RDS/Redshift in another account/region
  - Cross-account Data Catalog in Athena and Lake Formation resource 
  with cross account QuickSight [*](https://aws.amazon.com/blogs/big-data/use-amazon-athena-and-amazon-QuickSight-in-a-cross-account-environment/){:target="_blank"}
- ML Insights:
  - ML-powered anomaly detection
  - ML-powered forecasting
  - Autonarratives
  - Suggested insights

### Redshift

- Resizing clusters [*](https://docs.aws.amazon.com/redshift/latest/mgmt/managing-cluster-operations.html){:target="_blank"}
  - Elastic resize
    - Quickly add or remove nodes of same type
    - Cluster is down for a few minutes
    - Tries to keep connections open across the downtime
  - Classic resize
    - Change node type and/or remove number of nodes
    - Cluster is read-only for hours or days
  - Snapshot, restore, resize
    - Used to keep cluster available during a classic resize
    - Copy cluster, resize new cluster
- RA3 instances with managed storage
  - This gives you the flexibility to size your RA3 cluster based on the 
  amount of data you process daily without increasing your storage costs. 
  Built on the AWS Nitro System, RA3 instances with managed storage use high 
  performance SSDs for your hot data and Amazon S3 for your cold data, 
  providing ease of use, cost-effective storage, and fast query performance
  - Allow you to pay per hour for the compute and separately scale data 
  warehouse storage capacity without adding any additional compute resources 
  and paying only for what you use
  - Include Amazon Redshift Data Sharing, a simple and direct way to share 
  transactionally consistent data across Amazon Redshift data warehouses 
  (cross region, cross account) securely, without data movement or data 
  copying
  - Use automatic fine-grained data eviction and intelligent data pre-fetching 
  to deliver the performance of local SSD, while scaling storage automatically 
  to S3
- AQUA [*](https://aws.amazon.com/blogs/aws/new-aqua-advanced-query-accelerator-for-amazon-redshift/){:target="_blank"}
  - Advanced Query Accelerator
  - Available on ra3.4xl and ra3.16xl nodes
  - If data is on S3
  - AQUA pushes the computation needed to handle reduction and aggregation 
  queries closer to the data. This reduces network traffic, offloads work from 
  the CPUs in the RA3 nodes, and allows AQUA to improve the performance of 
  those queries by up to 10x, at no extra cost and without any code changes
- Redshift ML [*](https://aws.amazon.com/redshift/features/redshift-ml/){:target="_blank"}
  - Simply use SQL statements to create and train Amazon SageMaker machine 
  learning models using your Redshift data and then use these models to make 
  predictions
  - Redshift exports data to S3 and then SageMaker builds a model, creates 
  an endpoint which can be used from Redshift via SQL SELECT statements
  - Bring Your Own Model (BYOM) - Redshift ML supports using BYOM for local 
  or remote inference. You can use a model trained outside of Redshift with 
  Amazon SageMaker for in-database inference local in Amazon Redshift. You 
  can import SageMaker Autopilot and direct Amazon SageMaker trained models 
  for local inference 
  [*](https://docs.aws.amazon.com/redshift/latest/dg/tutorials_for_amazon_redshift_ml.html){:target="_blank"}