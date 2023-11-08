# data-engineering

This repository contains scripts to move your Spark workloads to Fabric Data Engineering (Spark).

## From Azure Synapse

[Migrating from Azure Synapse Spark to Fabric](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-overview?branch=release-ignite-fabric)

To use the migration scripts see the details below and read the guidance docs (resource links below).

- Export: indicates export from Azure Synapse support
- Import: indicates import to Fabric support

| Resource              | Export     | Import          |
|-----------------------|------------|-----------------|
| [Pools](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-pools?branch=release-ignite-fabric)                 | Supported  | Unsupported     |
| [Configurations](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-configurations?branch=release-ignite-fabric)       | Supported  | Unsupported     |
| [Libraries](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-libraries?branch=release-ignite-fabric)             | Supported  | Unsupported     |
| [Notebooks](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-notebooks?branch=release-ignite-fabric)            | Supported  | Supported (scripts)      |
| [Spark job definition](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-spark-job-definition?branch=release-ignite-fabric)  | Supported  | Supported (scripts)      |
| [HMS metastore](https://review.learn.microsoft.com/en-us/fabric/data-engineering/migrate-synapse-hms-metadata?branch=release-ignite-fabric)         | Supported  | Supported (scripts)      |  


** Note: ADLS Gen2 ACLs, linked services, mount points, workspace users/roles, Key Vault secrets, data and pipelines migrations not supported. See [differences between Fabric vs. Azure Synapse Spark](https://review.learn.microsoft.com/en-us/fabric/data-engineering/comparison-between-fabric-and-azure-synapse-spark?branch=release-ignite-fabric).