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
    EXEC migration.create_master_key_and_scoped_credential;

    -- Create External File Format - fabric_data_migration_ext_file_format
    EXEC migration.create_external_file_format;

    -- Create External Data Source
    EXEC migration.sp_create_external_data_source @adls_base_location = @adls_gen2_location,
            @credential_name ='fabric_migration_credential',@external_data_source_name='fabric_data_migration_ext_data_source';

    IF (object_id('tempdb.dbo.#cetas','U') IS NOT NULL) 
    DROP TABLE #cetas

    create table #cetas with(distribution=round_robin,heap) as
    select 
    sc.name SchName
        , tbl.name objName
        , 'IF (object_id('''+ sc.name + '.migration_' + tbl.name + ''',''U'') IS NOT NULL) DROP EXTERNAL TABLE ['+ sc.name + '].[migration_' + tbl.name +'];' AS DropStatement
        , 'CREATE EXTERNAL TABLE [' + sc.name + '].[migration_' + tbl.name + 
            '] WITH (LOCATION = ''/'+sc.name+'/'+tbl.name+'/''' + ',' + 
            ' DATA_SOURCE = fabric_data_migration_ext_data_source,' +
            ' FILE_FORMAT = fabric_data_migration_ext_file_format)' +
            ' AS SELECT * FROM [' + + sc.name + '].[' + tbl.name + '];' AS data_extract_statement   

    from sys.tables tbl
    inner join sys.schemas sc on  tbl.schema_id=sc.schema_id and tbl.is_external = 'false'
	AND sc.name !='migration'
    -- dont extract the migration schema, i.e. all this new code to help with migration

    SELECT * From #cetas;





	
