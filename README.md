### DDL Extraction Scripts pre-requisites

* Deploy the scripts in this repository (Data Extract Scripts folder) in the source database.
* The managed identity of Azure SQL Data Warehouse Server or Synapse Workspace should be added as a user.
* Following permissions must be given to the Managed Identity before running data extraction scripts
    - GRANT ADMINISTER DATABASE BULK OPERATIONS TO [Managed Service Identity];
    - GRANT ALTER ANY EXTERNAL DATA SOURCE TO [Managed Service Identity];
    - GRANT ALTER ANY EXTERNAL FILE FORMAT TO [Managed Service Identity];
* User running these scripts needs all of these permissions
    - ALTER SCHEMA permission on the local schema that will contain the new table or membership in the db_ddladmin fixed database role.
    - CREATE TABLE permission or membership in the db_ddladmin fixed database role.
    - SELECT permission on any objects referenced in the select_criteria.
