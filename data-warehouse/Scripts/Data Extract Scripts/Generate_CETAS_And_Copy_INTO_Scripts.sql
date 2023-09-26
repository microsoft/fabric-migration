IF object_id('migration.generate_data_extract_and_data_load_statements') IS NOT NULL
    DROP PROCEDURE migration.generate_data_extract_and_data_load_statements
GO

CREATE PROCEDURE migration.generate_data_extract_and_data_load_statements 
@storage_access_token VARCHAR(1024),
@external_data_source_base_location VARCHAR(1024)
/*

    Name: migration.create_temp_table_view_to_extract_data
    Description: This stored procedure creates a temporary table that stores all tables and its columns.
    
    Sample Execution: 
        EXEC migration.generate_data_extract_and_data_load_statements @storage_access_token = ''
        , @external_data_source_base_location = ''

*/
AS

IF (object_id('tempdb.dbo.#data_load','U') IS NOT NULL) 
    DROP TABLE #data_load

create table #data_load with(distribution=round_robin,heap) as
select 
   sc.name SchName
    , tbl.name objName
    , 'COPY INTO [' + + sc.name + '].[' + tbl.name + '] FROM ''' + @external_data_source_base_location + ''+sc.name+'/'+tbl.name+'/''' +
        ' WITH ( FILE_TYPE = ''PARQUET'', CREDENTIAL=(IDENTITY= ''Storage Account Key'', SECRET = '''+ @storage_access_token + '''))' AS data_load_statement

from sys.tables tbl
inner join sys.schemas sc on  tbl.schema_id=sc.schema_id and tbl.is_external = 'false'

SELECT * From #data_load;