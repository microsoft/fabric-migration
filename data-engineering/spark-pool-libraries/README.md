# spark-pool-libraries

You can list `spark3-client` libraries both in Azure Synapse Spark and Fabric by running this in a notebook:

 ```console
    import os

    dir_path = "/usr/hdp/current/spark3-client/jars"

    jar_files = [file for file in os.listdir(dir_path) if file.endswith(".jar")]

    for jar_file in jar_files:
        print(jar_file)
```

**Spark 3.3**
Synapse Spark 3.3 vs. Runtime 1.1 in Fabric (both Starter and Custom pools): there are some libraries with minor differences.

| Library Name      | Azure Synapse Spark                | Fabric Spark                       |
|:------------------|:-----------------------------------|:-----------------------------------|
| VegasConnector    | VegasConnector-3.3.07.jar          | VegasConnector-3.2.06.jar          |
| autotune-client   | autotune-client_2.12-1.5.0-3.3.jar | autotune-client_2.12-1.4.1-3.3.jar |
| autotune-common   | autotune-common_2.12-1.5.0-3.3.jar | autotune-common_2.12-1.4.1-3.3.jar |
| delta-core        | delta-core_2.12-2.2.0.7.jar        | delta-core_2.12-2.2.0.6.jar        |
| delta-iceberg     | delta-iceberg_2.12-2.2.0.7.jar     | delta-iceberg_2.12-2.2.0.6.jar     |
| delta-storage     | delta-storage-2.2.0.7.jar          | delta-storage-2.2.0.6.jar          |