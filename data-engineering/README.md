# data-engineering

This repository contains scripts to move your Spark workloads to Fabric Data Engineering (Spark).

## From Azure Synapse

To use the migration scripts see the details below and read guidance doc for each item (links below).

- Export: indicates export from Azure Synapse support
- Import: indicates import to Fabric support

| Item              | Export     | Import          |    |
|-----------------------|------------|-----------------|-----------------|
| Pools                 | Supported  | Unsupported     | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-pools?branch=release-ignite-fabric)
| Configurations      | Supported  | Unsupported     | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-configurations?branch=release-ignite-fabric) 
| Libraries            | Supported  | Unsupported     | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-libraries?branch=release-ignite-fabric) 
| Notebooks           | Supported  | Supported     | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-notebooks?branch=release-ignite-fabric) / [scripts](spark-notebooks/)
| Spark job definition  | Supported  | Supported     | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-job-definition?branch=release-ignite-fabric) / [scripts](spark-sjd/)
| HMS metastore(        | Supported  | Supported      |  [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-hms-metadata?branch=release-ignite-fabric) / [scripts](spark-catalog/hms/)

 
> **NOTE:** ADLS Gen2 ACLs, linked services, mount points, workspace users/roles, Key Vault secrets, data and pipelines migration not supported yet. 

- See [differences between Fabric vs. Azure Synapse Spark](https://review.learn.microsoft.com/en-us/fabric/data-engineering/comparison-between-fabric-and-azure-synapse-spark?branch=release-ignite-fabric)
- See [migrating from Azure Synapse Spark to Fabric](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-overview?branch=release-ignite-fabric)

**How to use import/export scripts**

* For notebook and Spark job definition, import the migration notebook in your Fabric workspace and follow notebook instructions.
* For HMS metadata, first import `nt-hms-export-metadata` notebook in your Azure Synapse workspace. This will output HMS metadata (databases, tables and partitions) to OneLake. Then import `nt-hms-import-metadata` notebook in your Fabric workspace, and follow notebook instructions.