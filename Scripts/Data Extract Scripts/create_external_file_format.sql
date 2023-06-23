IF object_id('dbo.create_external_file_format') IS NOT NULL
    DROP PROCEDURE dbo.create_external_file_format
GO

CREATE PROCEDURE dbo.create_external_file_format
/*

    Name: dbo.create_external_file_format
    Description: This stored procedure creates external file format. Defaulting to Parquet.
    
    Sample Execution: 
        EXEC dbo.create_external_file_format

*/
AS

BEGIN TRY

    -- Create Database Scoped Credential
    IF EXISTS (SELECT 1 FROM sys.external_file_formats WHERE name = 'fabric_data_migration_ext_file_format')
    BEGIN
        print('fabric_data_migration_ext_file_format file format exists already.');
    END
    ELSE 
    BEGIN
        CREATE EXTERNAL FILE FORMAT fabric_data_migration_ext_file_format
        WITH 
        (
            FORMAT_TYPE = PARQUET,
            DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
        );
        print('created external file format - fabric_data_migration_ext_file_format.');
    END
END TRY

BEGIN CATCH
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_STATE() AS ErrorState,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_MESSAGE() AS ErrorMessage;

    THROW;
END CATCH;
