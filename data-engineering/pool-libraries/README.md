# spark-pool-libraries

You can list `spark3-client` libraries both in Azure Synapse Spark and Fabric by running this in a notebook:

 ```console
    import os

    dir_path = "/usr/hdp/current/spark3-client/jars"

    jar_files = [file for file in os.listdir(dir_path) if file.endswith(".jar")]

    for jar_file in jar_files:
        print(jar_file)
```

TBC - add simple table

**Spark 3.3**
- Synapse Spark 3.3 vs. Runtime 1.1 in Fabric (both Starter and Custom pools): there are no differences between them.
- DBX (add runtime LTS) vs. Runtime 1.1 in Fabric (both Starter and Custom pools): TBC
- HDInsight 3.3 vs. Runtime 1.1 in Fabric (both Starter and Custom pools): TBC