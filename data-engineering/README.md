# data-engineering

This repository contains scripts to move your Spark workloads to Fabric Data Engineering (Spark).

## From Azure Synapse

To use the migration scripts see the details below and read guidance doc for each item (links below).

- Export: indicates export from Azure Synapse support
- Import: indicates import to Fabric support

| Item              | Export     | Import          |
|-----------------------|------------|-----------------|
| [Pools](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-pools?branch=release-ignite-fabric)                 | Supported  | Unsupported     |
| [Configurations](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-configurations?branch=release-ignite-fabric)       | Supported  | Unsupported     |
| [Libraries](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-libraries?branch=release-ignite-fabric)             | Supported  | Unsupported     |
| [Notebooks](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-notebooks?branch=release-ignite-fabric)            | Supported  | Supported ([scripts](spark-notebooks/))      |
| [Spark job definition](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-job-definition?branch=release-ignite-fabric)  | Supported  | Supported ([scripts](spark-sjd/))      |
| [HMS metastore](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-hms-metadata?branch=release-ignite-fabric)         | Supported  | Supported ([scripts](spark-catalog/hms/))      |  

 
> **NOTE:** ADLS Gen2 ACLs, linked services, mount points, workspace users/roles, Key Vault secrets, data and pipelines migration not supported yet. 

- See [differences between Fabric vs. Azure Synapse Spark](https://review.learn.microsoft.com/en-us/fabric/data-engineering/comparison-between-fabric-and-azure-synapse-spark?branch=release-ignite-fabric)
- See [migrating from Azure Synapse Spark to Fabric](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-overview?branch=release-ignite-fabric)

**How to use import/export scripts**

* For notebook and Spark job definition, import the migration notebook in your Fabric workspace and follow notebook instructions.
* For HMS metadata, first import `nt-hms-export-metadata` notebook in your Azure Synapse workspace. This will output HMS metadata (databases, tables and partitions) to OneLake. Then import `nt-hms-import-metadata` notebook in your Fabric workspace, and follow notebook instructions.