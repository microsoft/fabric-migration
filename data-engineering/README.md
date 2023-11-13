# data-engineering

This repository contains scripts to move your Spark workloads to Fabric Data Engineering (Spark).

## From Azure Synapse

To use the migration scripts see the details below and read guidance doc for each item (links below).

- Export: indicates export support from Azure Synapse
- Import: indicates import support to Fabric

| Item                 | Export    | Import      |                                                                                                                                                                   |
|----------------------|-----------|-------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Pools                | Supported | Unsupported | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-pools)                                  |
| Configurations       | Supported | Unsupported | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-configurations)                         |
| Libraries            | Supported | Unsupported | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-libraries)                              |
| Notebooks            | Supported | Supported   | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-notebooks) / [scripts](spark-notebooks/)      |
| Spark job definition | Supported | Supported   | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-job-definition) / [scripts](spark-sjd/) |
| HMS metastore        | Supported | Supported   | [doc](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-hms-metadata) / [scripts](spark-catalog/hms/) |

 
> **NOTE:** ADLS Gen2 ACLs, linked services, mount points, workspace users/roles, Key Vault secrets, data and pipelines migration not supported yet. 

- See [differences between Fabric vs. Azure Synapse Spark](https://review.learn.microsoft.com/en-us/fabric/data-engineering/comparison-between-fabric-and-azure-synapse-spark)
- See [migrating from Azure Synapse Spark to Fabric](https://aka.ms/fabric-migrate-synapse-spark)

**How to use import/export scripts**

* For notebook and Spark job definition, import the migration notebook in your Fabric workspace and follow notebook instructions.
* For HMS metadata, first import `nt-hms-export-metadata` notebook in your Azure Synapse workspace. This will output HMS metadata (databases, tables and partitions) to OneLake. Then import `nt-hms-import-metadata` notebook in your Fabric workspace, and follow notebook instructions.