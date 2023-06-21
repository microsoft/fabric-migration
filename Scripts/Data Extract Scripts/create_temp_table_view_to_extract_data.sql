CREATE PROCEDURE dbo.create_temp_table_view_to_extract_data
/*

    Name: dbo.create_temp_table_view_to_extract_data
    Description: This stored procedure creates a temporary table that stores all tables and its columns.
    
    Sample Execution: 
        EXEC dbo.create_temp_table_view_to_extract_data

*/
AS

IF (object_id('dbo.table_info_for_data_extract','U') IS NOT NULL) 
    DROP TABLE dbo.table_info_for_data_extract

create table dbo.table_info_for_data_extract with(distribution=round_robin,heap) as
select 
    tbl.object_id,sc.name SchName
    , tbl.name tblName
    , c.column_id colid
    , c.name colname
    , t.name as coltype
    , c.max_length colmaxlength
    , c.precision colprecision
    , c.scale colscale
    , c.is_nullable colnullable
    , c.collation_name
from sys.columns c
join sys.tables tbl on tbl.object_id=c.object_id
join sys.pdw_column_distribution_properties d on c.object_id = d.object_id and c.column_id = d.column_id
join sys.types t on t.user_type_id = c.user_type_id
inner join sys.schemas sc on  tbl.schema_id=sc.schema_id
left join sys.default_constraints dc on c.default_object_id =dc.object_id and c.object_id =dc.parent_object_id;

SELECT * From dbo.table_info_for_data_extract;