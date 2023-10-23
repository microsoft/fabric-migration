### spark-pool-libraries

You can list `spark3-client` libraries both in Azure Synapse Spark and Fabric by running this in a notebook:

 ```console
    import os

    dir_path = "/usr/hdp/current/spark3-client/jars"

    jar_files = [file for file in os.listdir(dir_path) if file.endswith(".jar")]

    for jar_file in jar_files:
        print(jar_file)
```

### spark-pool-configurations

You can list default configurations both in Azure Synapse Spark and Fabric by running this in a notebook:

 ```console
    spark.sparkContext.getConf().getAll()
```

**Spark 3.3**
Relevant properties in Synapse Spark 3.3 vs. Runtime 1.1 in Fabric (custom pools).


| Property Name                                       | Azure Synapse Spark   | Fabric Spark  |
|:----------------------------------------------------|:----------------------|:--------------|
| spark.scheduler.mode                                | FIFO                  | FAIR          |
| spark.ms.autotune.enabled                           | false                 | true          |
| spark.microsoft.delta.optimizeWrite.enabled         | false                 | true          |
| spark.sql.parquet.vorder.enabled                    | false                 | true          |
| spark.microsoft.delta.merge.lowShuffle.enabled      | true                  | true          |
| spark.livy.synapse.session-warmup.enabled           | false                 | true          |
| spark.synapse.vegas.useCase                         | true                  | true          |