CREATE PROCEDURE dbo.sp_create_external_data_source 
@adls_base_location VARCHAR(1024),
@credential_name VARCHAR(100),
@external_data_source_name VARCHAR(100)

/*

    Name: dbo.sp_create_external_data_source
    Description: This stored procedure creates exernal data source
    
    Parameters:
    @adls_base_location - abfss path of a storage account and container. Example: abfss://primary@pvenkattestsa.dfs.core.windows.net/. Make sure to include a / at the end of the abfss path
    @credential_name - default credential name - fabric_migration_credential
    @external_data_source_name - name of the external data source, default name is fabric_data_migration_ext_data_source

    Sample Execution: 
        EXEC dbo.sp_create_external_data_source @adls_base_location = 'abfss://primary@pvenkattestsa.dfs.core.windows.net/data/',
        @credential_name ='fabric_migration_credential',@external_data_source_name='fabric_data_migration_ext_data_source'

*/
AS
SELECT @adls_base_location, @credential_name, @external_data_source_name
BEGIN TRY

    IF EXISTS (SELECT 1 FROM sys.external_data_sources WHERE name = @external_data_source_name)
    BEGIN
        print('Dropping '+ @external_data_source_name + '.');
        DECLARE @drop_extdatasource_string VARCHAR(8000)
        SET @drop_extdatasource_string =  'DROP EXTERNAL DATA SOURCE ' + @external_data_source_name
        EXEC(@drop_extdatasource_string);
    END

    DECLARE @create_extdatasource_string VARCHAR(8000)
    SET @create_extdatasource_string =     
        'CREATE EXTERNAL DATA SOURCE '+ @external_data_source_name +' WITH (TYPE = hadoop, LOCATION = ' + '''' + @adls_base_location + '''' + ', CREDENTIAL = ' + @credential_name + ');'
    SELECT @create_extdatasource_string;
    EXEC(@create_extdatasource_string);
    print(@external_data_source_name+ ' is created.');

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