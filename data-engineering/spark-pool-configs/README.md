# spark-pool-configurations

You can list default configurations both in Azure Synapse Spark and Fabric by running this in a notebook:

 ```console
    spark.sparkContext.getConf().getAll()
```

**Spark 3.3**
Synapse Spark 3.3 vs. Runtime 1.1 in Fabric (Custom pools).


| Property Name                                       | Azure Synapse Spark   | Fabric Spark  |
|:----------------------------------------------------|:----------------------|:--------------|
| spark.scheduler.mode                                | FIFO                  | FAIR          |
| spark.ms.autotune.enabled                           | false                 | true          |
| spark.microsoft.delta.optimizeWrite.enabled         | false                 | true          |
| spark.sql.parquet.vorder.enabled                    | false                 | true          |
| spark.trident.jarDirLoader.enabled                  | false                 | true          |
| spark.livy.synapse.session-warmup.enabled           | false                 | true          |
| spark.sql.spark.cluster.type                        | synapse               | trident       |

spark.sql.extensions values are also different: 

- Synapse:   com.microsoft.vegas.common.VegasExtensionBuilder,com.microsoft.peregrine.spark.extensions.SparkExtensionsSynapse,io.delta.sql.DeltaSparkSessionExtension,com.microsoft.azure.synapse.ml.predict.SynapsePredictExtensions
- Fabric: com.microsoft.vegas.common.VegasExtensionBuilder,com.microsoft.peregrine.spark.extensions.SparkExtensionsSynapse,io.delta.sql.DeltaSparkSessionExtension,com.microsoft.azure.synapse.ml.predict.PredictExtension,com.microsoft.autotune.client.AutoTuneExtensions,org.apache.spark.lighter.server.sql.LighterSQLExtensions