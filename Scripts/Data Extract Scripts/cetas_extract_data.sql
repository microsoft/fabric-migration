CREATE PROCEDURE dbo.sp_cetas_extract_script
@external_data_source_base_location VARCHAR(1024)
/*

    Name: dbo.sp_cetas_extract_script
    Description: This stored procedure uses system tables to generate CETAS script for extracting data to a data lake store
    Parameters: None

*/
AS

-- Create master encryption key and database scoped credential with managed identity
EXEC dbo.create_master_key_and_scoped_credential;

-- Create External File Format - fabric_data_migration_ext_file_format
EXEC dbo.create_external_file_format;

-- Create External Data Source
EXEC dbo.sp_create_external_data_source @adls_base_location = @external_data_source_base_location,
        @credential_name ='fabric_migration_credential',@external_data_source_name='fabric_data_migration_ext_data_source';

-- Create a temporary table to hold the table data in dbo.table_info_for_data_extract;
EXEC dbo.create_temp_table_view_to_extract_data;

SELECT 'CREATE EXTERNAL TABLE ' + SchName + '.' + tblName + 
        ' WITH (LOCATION = ''/'+SchName+'/'+tblName+'/''' + ',' + 
        ' DATA_SOURCE = fabric_data_migration_ext_data_source,' +
        ' FILE_FORMAT = fabric_data_migration_ext_file_format)' +
        ' AS SELECT * FROM ' + + SchName + '.' + tblName + ';'
        FROM dbo.table_info_for_data_extract;



select * from dbo.table_info_for_data_extract;