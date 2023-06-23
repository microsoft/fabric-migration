IF object_id('dbo.generate_data_extract_and_data_load_statements') IS NOT NULL
    DROP PROCEDURE dbo.generate_data_extract_and_data_load_statements
GO

CREATE PROCEDURE dbo.generate_data_extract_and_data_load_statements 
@storage_access_token VARCHAR(1024),
@external_data_source_base_location VARCHAR(1024)
/*

    Name: dbo.create_temp_table_view_to_extract_data
    Description: This stored procedure creates a temporary table that stores all tables and its columns.
    
    Sample Execution: 
        EXEC dbo.generate_data_extract_and_data_load_statements @storage_access_token = ''
        , @external_data_source_base_location = ''

*/
AS

IF (object_id('tempdb.dbo.#table_info_for_data_extract_and_data_load','U') IS NOT NULL) 
    DROP TABLE dbo.table_info_for_data_extract_and_data_load

create table #table_info_for_data_extract_and_data_load with(distribution=round_robin,heap) as
select 
   sc.name SchName
    , tbl.name objName
    , 'IF (object_id('''+ sc.name + '.migration_' + tbl.name + ''',''U'') IS NOT NULL) DROP EXTERNAL TABLE ['+ sc.name + '].[migration_' + tbl.name +'];' AS DropStatement
    , 'CREATE EXTERNAL TABLE [' + sc.name + '].[migration_' + tbl.name + 
        '] WITH (LOCATION = ''/'+sc.name+'/'+tbl.name+'/''' + ',' + 
        ' DATA_SOURCE = fabric_data_migration_ext_data_source,' +
        ' FILE_FORMAT = fabric_data_migration_ext_file_format)' +
        ' AS SELECT * FROM [' + + sc.name + '].[' + tbl.name + '];' AS data_extract_statement
    , 'COPY INTO [' + + sc.name + '].[' + tbl.name + '] FROM ''' + @external_data_source_base_location + ''+sc.name+'/'+tbl.name+'/''' +
        ' WITH ( FILE_TYPE = ''PARQUET'', CREDENTIAL=(IDENTITY= ''Storage Account Key'', SECRET = '''+ @storage_access_token + '''))' AS data_load_statement

from sys.tables tbl
inner join sys.schemas sc on  tbl.schema_id=sc.schema_id

SELECT * From #table_info_for_data_extract_and_data_load;