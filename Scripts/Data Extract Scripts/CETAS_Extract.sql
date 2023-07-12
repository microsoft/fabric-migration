IF object_id('migration.sp_cetas_extract_script') IS NOT NULL
    DROP PROCEDURE migration.sp_cetas_extract_script;
GO

CREATE PROCEDURE migration.sp_cetas_extract_script
@adls_gen2_location VARCHAR(1024),
@storage_access_token VARCHAR(1024)
/*

    Name: migration.sp_cetas_extract_script
    Description: This stored procedure uses system tables to generate CETAS script for extracting data to a data lake store
    Parameters: 
        @adls_gen2_location - Base storage location of data stored in adls gen2 storage
        @storage_access_token - Storage Account access key
*/
AS

-- Create master encryption key and database scoped credential with managed identity
EXEC dbo.create_master_key_and_scoped_credential;

-- Create External File Format - fabric_data_migration_ext_file_format
EXEC dbo.create_external_file_format;

-- Create External Data Source
EXEC dbo.sp_create_external_data_source @adls_base_location = @adls_gen2_location,
        @credential_name ='fabric_migration_credential',@external_data_source_name='fabric_data_migration_ext_data_source';